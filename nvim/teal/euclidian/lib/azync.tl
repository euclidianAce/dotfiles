-- An attempt to recreate Zig's 'colorless' async/await (+suspend/resume) on top of Lua's coroutines
-- Since Zig's coroutines are pretty barebones (just implementing suspend and resume ops), it's real easy to implement with Lua's coroutines (which are also pretty barebones)
-- honestly this is barely a wrapper and the only 'new' things are stuff like
--    `nosuspend`, which is just an assertion that a coroutine doesn't yield to the running function

local record Frame<T...>
	_t: thread
	_awaiter: Frame<any>
end

local record Packed
	{any}
	n: integer
end

local frameCache <const>: {thread:any} = setmetatable({}, { __mode = "k" }) -- thread -> Frame
local values <const>: {any:Packed} = setmetatable({}, { __mode = "k" }) -- Frame -> awaited value
local status <const> = coroutine.status

local suspendBlock <const> = {} -- This is just a dummy value to signal when a suspend has a block
local function suspend<T...>(fn: function(Frame<T>))
	coroutine.yield(fn and suspendBlock, fn)
end

local function isDead<T...>(frame: Frame<T>): boolean
	if type(frame) ~= "table" then
		print(debug.getinfo(2))
		error("???")
	end
	return status(frame._t) == "dead"
end

local function packTail(b: boolean, ...: any): boolean, Packed
	return b, {
		n = select("#", ...),
		...
	}
end

local function internalResume(frame: Frame<any>, ...: any): any...
	if isDead(frame) then
		error("Resumed an async function which already returned", 3)
	end

	local ok <const>, vals <const> = packTail(coroutine.resume(frame._t, ...))
	if not ok then
		error(vals[1], 3)
	end

	if isDead(frame) then
		values[frame] = vals
		if frame._awaiter then
			internalResume(frame._awaiter as Frame<any>)
		end
	elseif vals[1] == suspendBlock then
		return (vals[2] as function)(frame)
	end
end

local scheduledInternalResume <const> = vim.schedule_wrap(internalResume)

local function resume<T...>(frame: Frame<T>)
	internalResume(frame as Frame<any>)
end

local function resumeSchedule<T...>(frame: Frame<T>)
	scheduledInternalResume(frame as Frame<any>)
end

local function currentFrame(): Frame<any>
	local co <const> = coroutine.running()
	return frameCache[co] as Frame<any>
end

local function unpackFrameResult<Ret...>(frame: Frame<Ret>): Ret
	return (unpack as function(any, integer, integer): Ret)
		(values[frame], 1, values[frame].n)
end

local function await<Ret...>(frame: Frame<Ret>): Ret
	if not isDead(frame) then
		assert(frame._awaiter == nil, "async function awaited twice")
		frame._awaiter = assert(currentFrame(), "Not running in an async function")
		coroutine.yield()
		assert(isDead(frame), "awaiting function resumed")
	end
	return unpackFrameResult(frame)
end

local function wrapCallable<Ret..., Args...>(fn: function(...: Args): Ret): function(Args): Ret
	if type(fn) ~= "function" then
		return function(...: Args): Ret return fn(...) end
	end
	return fn
end

local function nosuspend<Ret..., Args...>(fn: (function(...: Args): Ret), ...: Args): Ret
	local frame <const> = { _t = coroutine.create(wrapCallable(fn)) }
	frameCache[frame._t] = frame
	internalResume(frame as Frame<any>, ...)
	if not isDead(frame) then
		error("Function suspended in a nosuspend", 2)
	end
	return unpackFrameResult(frame)
end

local function async<Ret..., Args...>(fn: (function(...: Args): Ret), ...: Args): Frame<Ret>
	local co <const> = coroutine.create(wrapCallable(fn))
	local f <const> = { _t = co }
	frameCache[co] = f
	internalResume(f, ...)
	return f
end

local function asyncSchedule<Ret..., Args...>(fn: (function(...: Args): Ret), ...: Args): Frame<Ret>
	local co <const> = coroutine.create(wrapCallable(fn))
	local f <const> = { _t = co }
	frameCache[co] = f
	vim.schedule_wrap(internalResume)(f, ...)
	return f
end

local function asyncFn<Ret..., Args...>(fn: (function(...: Args): Ret)): function(Args): Frame<Ret>
	return function(...: Args): Frame<Ret>
		return async(fn, ...)
	end
end

local function randomRange(n: integer): function(): integer
	local range <const> = {}
	for i = 1, n do
		range[i] = i
	end
	for i = n, 1, -1 do
		local j <const> = math.random(1, i)
		range[i], range[j] = range[j], range[i]
	end
	local i = 0
	return function(): integer
		i = i + 1
		return range[i]
	end
end

local function selectFrame<Ret...>(...: Frame<Ret>): Frame<Ret>
	local current <const> = assert(currentFrame(), "Not running in an async function")

	local nframes <const> = select("#", ...)
	local frames <const> = { ... }

	-- just like await, short circuit if any frames are ready
	for i in randomRange(nframes) do
		assert(not frames[i]._awaiter, "async function awaited twice (in select)")
		if isDead(frames[i]) then
			return frames[i]
		end
	end

	-- if no frames are ready, set up awaiters and yield
	for i = 1, nframes do
		frames[i]._awaiter = current
	end
	coroutine.yield()

	for i in randomRange(nframes) do
		if isDead(frames[i]) then
			return frames[i]
		end
	end
	error("selecting function resumed", 2)
end

local function selectAwait<Ret...>(...: Frame<Ret>): Ret
	local f <const> = selectFrame(...)
	assert(isDead(f))
	return unpackFrameResult(f)
end

return {
	suspend = suspend,
	resume = resume,
	async = async,
	await = await,
	nosuspend = nosuspend,
	currentFrame = currentFrame,
	select = selectFrame,
	selectAwait = selectAwait,

	asyncSchedule = asyncSchedule,
	resumeSchedule = resumeSchedule,
	asyncFn = asyncFn,

	Frame = Frame,
}

