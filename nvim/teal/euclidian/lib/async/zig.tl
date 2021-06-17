
-- An attempt to recreate Zig's 'colorless' async/await (+suspend/resume) on top of Lua's coroutines
-- Since Zig's coroutines are pretty barebones (just implementing suspend and resume ops), it's real easy to implement with Lua's coroutines (which are also pretty barebones)
-- honestly this is barely a wrapper and the only 'new' things are stuff like
--    `nosuspend`, which is just an assertion that a coroutine doesn't yield to the running function

local record Frame<T...>
	_t: thread
	_awaiter: Frame<any>
end

local frames <const>: table = setmetatable({}, { __mode = "k" })
local suspendBlock <const> = {} -- This is just a dummy value to signal when a suspend has a block
local status <const> = coroutine.status

local function suspend<T...>(fn: function(Frame<T>))
	coroutine.yield(fn and suspendBlock, fn)
end

local function isDead<T...>(frame: Frame<T>): boolean
	return status(frame._t) == "dead"
end

local record Packed
	{any}
	n: integer
end

local values <const>: {any:Packed} = setmetatable({}, { __mode = "k" }) -- Frame -> awaited value

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

local function resume<T...>(frame: Frame<T>)
	internalResume(frame as Frame<any>)
end

local function currentFrame(): Frame<any>
	local co <const> = coroutine.running()
	return frames[co] as Frame<any>
end

-- TODO: don't use this casting hack, also this isn't properly type checked, but is ignored
local function await<Ret...>(frame: Frame<Ret>): Ret
	if not isDead(frame) then
		assert(frame._awaiter == nil, "async function awaited twice")
		frame._awaiter = assert(currentFrame(), "Not running in an async function")
		coroutine.yield()
		assert(isDead(frame), "awaiting function resumed")
	end
	return (unpack as function(any, integer, integer): Ret)(values[frame], 1, values[frame].n)
end

local function nosuspend<Ret..., Args...>(fn: (function(...: Args): Ret), ...: Args): Ret
	local frame <const> = { _t = coroutine.create(fn) }
	frames[frame._t] = frame
	internalResume(frame as Frame<any>, ...)
	if not isDead(frame) then
		error("Function suspended in a nosuspend", 2)
	end
	return (unpack as function(any, integer, integer): Ret)(values[frame], 1, values[frame].n)
end

local function async<Ret..., Args...>(fn: (function(...: Args): Ret), ...: Args): Frame<Ret>
	local co <const> = coroutine.create(fn)
	local f <const> = { _t = co }
	frames[co] = f
	internalResume(f, ...)
	return f
end

local function asyncFn<Ret..., Args...>(fn: (function(...: Args): Ret)): function(Args)
	return function(...: Args)
		async(fn, ...)
	end
end

return {
	suspend = suspend,
	resume = resume,
	async = async,
	await = await,
	nosuspend = nosuspend,
	currentFrame = currentFrame,

	asyncFn = asyncFn,

	Frame = Frame,
}
