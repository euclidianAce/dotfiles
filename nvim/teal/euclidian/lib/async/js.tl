
-- An adaptation of LowLevelJavaScript's "Promises from scratch" for Lua
--    This is actually (imho) a bit nicer to use since the js version relies on generator functions,
--    but lua has fully fledged coroutines so we dont need to worry about passing generators vs functions since we can just coroutine.create any function

local enum State
	"pending"
	"fulfilled"
	"rejected"
end

local record Promise<T>
end

local function weak<T>(t: T): T
	return setmetatable(t, { __mode = "k", })
end

-- Private fields
--    We use any here because we dont have
--    dependent types like {Promise<T> : T}
local states: {any:State} = weak({})
local values: {any:any} = weak({})
local thens: {any:{{any, any, any}}} = weak({})

-- Promises

local propagateThens: function<T>(Promise<T>)
local propagateElses: function<T>(Promise<T>)

local function onFulfilled<T>(p: Promise<T>, val: T)
	if states[p] == "pending" then
		states[p] = "fulfilled"
		values[p] = val
		propagateThens(p)
	end
end

local function onRejected<T>(p: Promise<T>, val: T)
	if states[p] == "pending" then
		states[p] = "rejected"
		values[p] = val
		propagateElses(p)
	end
end

local function new<T>(fn: function(function(T), function(T))): Promise<T>
	local p <const> = setmetatable({} as Promise<T>, { __index = Promise })
	states[p] = "pending"
	thens[p] = {}

	if fn then
		vim.schedule(function()
			fn(
				function(val: T)
					onFulfilled(p, val)
				end,
				function(val: T)
					onRejected(p, val)
				end
			)
		end)
	end

	return p
end

local uv <const> = vim.loop
-- a promise that runs in a new thread, uses string.dump on `fn` so all caveats
-- that apply to it apply here as well
local function newThreaded<T>(fn: function(function(T), function(T), ...: uv.Threadarg), ...: uv.Threadarg): Promise<T>
	local p <const> = setmetatable({} as Promise<T>, { __index = Promise })
	states[p] = "pending"
	thens[p] = {}
	if fn then
		local res, rej: uv.Async, uv.Async
		res = uv.new_async(function(val: uv.Threadarg)
			onFulfilled(p, val as T)
			res:close()
		end)
		rej = uv.new_async(function(val: uv.Threadarg)
			onRejected(p, val as T)
			res:close()
		end)

		uv.new_thread(
			function(sfunc: string, resAsync: uv.Async, rejAsync: uv.Async, ...: uv.Threadarg)
				local func = loadstring(sfunc) as function
				func(
					function(val: T)
						resAsync:send(val as uv.Threadarg)
					end,
					function(val: T)
						rejAsync:send(val as uv.Threadarg)
					end,
					...
				)
			end,
			string.dump(fn),
			res as uv.Threadarg, rej as uv.Threadarg,
			...
		)
	end

	return p
end

function Promise.andThen<T, K>(self: Promise<T>, thenFn: function(T): (K), elseFn: function(T)): Promise<K>
	local p <const> = new()
	local s <const> = states[self]

	table.insert(thens[self], {p, thenFn, elseFn})

	if s == "fulfilled" then
		propagateThens(self)
	elseif s == "rejected" then
		propagateElses(self)
	end

	return p
end

function Promise.orElse<T>(self: Promise<T>, elseFn: function(T)): Promise<T>
	return self:andThen(nil, elseFn)
end

local function isPromise(t: any): boolean
	local mt <const> = getmetatable(t)
	return mt and mt.__index == Promise
end

propagateThens = function<T>(p: Promise<T>)
	for _, t in ipairs(thens[p]) do
		local controlledPromise <const> = t[1] as Promise<T>
		local fn <const> = t[2] as function

		if fn then
			local valOrPromise = fn(values[p])
			if isPromise(valOrPromise) then
				(valOrPromise as Promise<T>):andThen(
					function(val: T): nil onFulfilled(controlledPromise, val) end,
					function(val: T) onRejected(controlledPromise, val) end
				)
			else
				onFulfilled(controlledPromise, valOrPromise as T)
			end
		else
			onFulfilled(controlledPromise, values[p] as T)
		end
	end
	thens[p] = {}
end

propagateElses = function<T>(p: Promise<T>)
	for _, t in ipairs(thens[p]) do
		local controlledPromise <const> = t[1] as Promise<T>
		local catchFn <const> = t[3] as function

		if catchFn then
			local valOrPromise = catchFn(values[p])
			if isPromise(valOrPromise) then
				(valOrPromise as Promise<T>):andThen(
					function(val: T): nil onFulfilled(controlledPromise, val) end,
					function(val: T) onRejected(controlledPromise, val) end
				)
			else
				onFulfilled(controlledPromise, valOrPromise as T)
			end
		else
			onFulfilled(controlledPromise, values[p] as T)
		end
	end
end

-- Async/Await on top of Promises
local ts: {thread:boolean} = weak({})
local function async<T>(fn: function(): T): function(): Promise<T>
	return function(): Promise<T>
		local co = coroutine.create(fn)
		ts[co] = true
		local function resume(...: any): boolean, T
			return coroutine.resume(co, ...) as (boolean, T)
		end

		local function asyncStuff(ok: boolean, val: T): T
			if not ok then
				error(val as string)
			end
			if coroutine.status(co) == "dead" then
				return val as T
			end
			if isPromise(val) then
				local res = function(v: T): nil asyncStuff(resume(v)) end
				;(val as Promise<T>):andThen(res, res)
			else
				return asyncStuff(resume(val))
			end
		end

		return new(function(res: function(T))
			res(asyncStuff(resume()))
			ts[co] = false
		end)
	end
end

local function await<T>(val: function(): Promise<T> | T): T
	local t = coroutine.running()
	if ts[t] then
		if val is function(): T then
			return coroutine.yield(val()) as T
		else
			return coroutine.yield(val) as T
		end
	else
		error("Top level await not supported")
	end
end

return {
	a = {
		wait = await,
		sync = async,
	},

	promise = {
		new = new,
		newThreaded = newThreaded,
		resolve = function<T>(val: T): Promise<T>
			local p <const> = setmetatable({} as Promise<T>, { __index = Promise })
			states[p] = "fulfilled"
			values[p] = val
			thens[p] = {}
			return p
		end,
		reject = function<T>(val: T): Promise<T>
			local p <const> = setmetatable({} as Promise<T>, { __index = Promise })
			states[p] = "rejected"
			values[p] = val
			thens[p] = {}
			return p
		end,
	},

	Promise = Promise,
	State = State,
}

