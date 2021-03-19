local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine



local Frame = {}




local frames = setmetatable({}, { __mode = "k" })
local suspendBlock = {}
local status = coroutine.status

local function errIf(cond, msg, lvl)
   if cond then
      error(msg, lvl + 1)
   end
end

local function suspend(fn)
   coroutine.yield(fn and suspendBlock, fn)
end

local function internalResume(frame, ...)
   errIf(status(frame._t) == "dead", "Resumed an async function which already returned", 2)
   local ok, val, fn = coroutine.resume(frame._t, ...)
   errIf(not ok, val, 3)
   if val == suspendBlock then
      return fn(frame)
   elseif status(frame._t) == "dead" then
      frame._v = val
   end
end
local function resume(frame)
   internalResume(frame)
end

local function await(frame)
   while status(frame._t) ~= "dead" do
      internalResume(frame)
      if status(frame._t) ~= "dead" then
         suspend()
      end
   end
   return frame._v
end

local function currentFrame()
   local co = coroutine.running()
   return frames[co]
end

local function nosuspend(fn, ...)
   local frame = { _t = coroutine.create(fn) }
   frames[frame._t] = frame
   internalResume(frame, ...)
   errIf(status(frame._t) ~= "dead", "Function suspended in a nosuspend", 2)
   return frame._v
end

local function async(fn, ...)
   local co = coroutine.create(fn)
   local f = { _t = co }
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