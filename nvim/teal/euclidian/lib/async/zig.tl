
-- An attempt to recreate Zig's 'colorless' async/await (+suspend/resume) on top of Lua's coroutines

local record Frame<T>
	_t: thread
	_v: T
end

local frames <const>: table = setmetatable({}, { __mode = "k" })
local suspendBlock <const> = {} -- This is just a dummy value to signal when a suspend has a block
local status <const> = coroutine.status

local function errIf(cond: boolean, msg: string, lvl: number)
	if cond then
		error(msg, lvl + 1)
	end
end

local function suspend(fn: function)
	coroutine.yield(fn and suspendBlock, fn)
end

local function internalResume<T>(frame: Frame<T>, ...: any): any...
	errIf(status(frame._t) == "dead", "Resumed an async function which already returned", 2)
	local ok, val, fn = coroutine.resume(frame._t, ...) as (boolean, T, function(Frame<T>): any)
	errIf(not ok, val as string, 3)
	if val == suspendBlock then
		return fn(frame)
	elseif status(frame._t) == "dead" then
		frame._v = val
	end
end
local function resume<T>(frame: Frame<T>)
	internalResume(frame)
end

local function await<T>(frame: Frame<T>): T
	while status(frame._t) ~= "dead" do
		internalResume(frame)
		if status(frame._t) ~= "dead" then
			suspend()
		end
	end
	return frame._v
end

local function currentFrame(): Frame<any>
	local co <const> = coroutine.running()
	return frames[co] as Frame<any>
end

local function nosuspend<T, K>(fn: function(...: K): (T), ...: K): T
	local frame = { _t = coroutine.create(fn) } as Frame<T>
	frames[frame._t] = frame
	internalResume(frame, ...)
	errIf(status(frame._t) ~= "dead", "Function suspended in a nosuspend", 2)
	return frame._v
end

local function async<T, K>(fn: function(...: K): (T), ...: K): Frame<T>
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
