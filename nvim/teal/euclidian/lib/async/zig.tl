
-- An attempt to recreate Zig's 'colorless' async/await (+suspend/resume) on top of Lua's coroutines
-- Since Zig's coroutines are pretty barebones (just implementing suspend and resume ops), it's real easy to implement with Lua's coroutines (which are also pretty barebones)
-- honestly this is barely a wrapper and the only 'new' things are stuff like
--    `nosuspend`, which is just an assertion that a coroutine doesn't yield to the running function

local record Frame<T>
	_t: thread
	_v: T
	_awaiter: thread
end

local frames <const>: table = setmetatable({}, { __mode = "k" })
local suspendBlock <const> = {} -- This is just a dummy value to signal when a suspend has a block
local status <const> = coroutine.status

local function suspend<T>(fn: function(Frame<T>))
	coroutine.yield(fn and suspendBlock, fn)
end

local function isDead<T>(frame: Frame<T>): boolean
	return status(frame._t) == "dead"
end

local function internalResume<T>(frame: Frame<T>, ...: any): any...
	if isDead(frame) then
		error("Resumed an async function which already returned", 3)
	end

	local ok <const>, val <const>, fn <const>
		= coroutine.resume(frame._t, ...) as (boolean, T, function(Frame<T>): any)
	if not ok then
		error(val, 3)
	end

	if isDead(frame) then
		frame._v = val
		if frame._awaiter then
			local awaiterok, awaiterval = coroutine.resume(frame._awaiter) as (boolean, T)
			if not awaiterok then
				error(awaiterval, 3)
			end
		end
	end

	if val == suspendBlock then
		return fn(frame)
	end
end

local function resume<T>(frame: Frame<T>)
	internalResume(frame)
end

local function await<T>(frame: Frame<T>): T
	if not isDead(frame) then
		assert(frame._awaiter == nil, "async function awaited twice")
		frame._awaiter = coroutine.running()
		coroutine.yield()
		assert(isDead(frame), "awaiting function resumed")
	end
	return frame._v
end

local function currentFrame(): Frame<any>
	local co <const> = coroutine.running()
	return frames[co] as Frame<any>
end

local function nosuspend<T, K>(fn: function(...: K): (T), ...: K): T
	local frame <const> = { _t = coroutine.create(fn) } as Frame<T>
	frames[frame._t] = frame
	internalResume(frame, ...)
	if not isDead(frame) then
		error("Function suspended in a nosuspend", 2)
	end
	return frame._v
end

local function async<T, K>(fn: (function(...: K): T), ...: K): Frame<T>
	local co <const> = coroutine.create(fn)
	local f <const> = { _t = co } as Frame<T>
	frames[co] = f
	internalResume(f, ...)
	return f
end

return {
	suspend = suspend,
	resume = resume,
	async = async,
	await = await,
	nosuspend = nosuspend,
	currentFrame = currentFrame,

	Frame = Frame,
}
