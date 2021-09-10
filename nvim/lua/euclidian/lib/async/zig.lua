





local Frame = {}




local frames = setmetatable({}, { __mode = "k" })
local suspendBlock = {}
local status = coroutine.status

local function suspend(fn)
   coroutine.yield(fn and suspendBlock, fn)
end

local function isDead(frame)
   return status(frame._t) == "dead"
end

local Packed = {}




local values = setmetatable({}, { __mode = "k" })

local function packTail(b, ...)
   return b, {
      n = select("#", ...),
      ...,
   }
end

local function internalResume(frame, ...)
   if isDead(frame) then
      error("Resumed an async function which already returned", 3)
   end

   local ok, vals = packTail(coroutine.resume(frame._t, ...))
   if not ok then
      error(vals[1], 3)
   end

   if isDead(frame) then
      values[frame] = vals
      if frame._awaiter then
         internalResume(frame._awaiter)
      end
   elseif vals[1] == suspendBlock then
      return (vals[2])(frame)
   end
end

local function resume(frame)
   internalResume(frame)
end

local function currentFrame()
   local co = coroutine.running()
   return frames[co]
end

local function await(frame)
   if not isDead(frame) then
      assert(frame._awaiter == nil, "async function awaited twice")
      frame._awaiter = assert(currentFrame(), "Not running in an async function")
      coroutine.yield()
      assert(isDead(frame), "awaiting function resumed")
   end
   return (unpack)(values[frame], 1, values[frame].n)
end

local function wrapCallable(fn)
   if type(fn) ~= "function" then
      return function(...) return fn(...) end
   end
   return fn
end

local function nosuspend(fn, ...)
   local frame = { _t = coroutine.create(wrapCallable(fn)) }
   frames[frame._t] = frame
   internalResume(frame, ...)
   if not isDead(frame) then
      error("Function suspended in a nosuspend", 2)
   end
   return (unpack)(values[frame], 1, values[frame].n)
end

local function async(fn, ...)
   local co = coroutine.create(wrapCallable(fn))
   local f = { _t = co }
   frames[co] = f
   internalResume(f, ...)
   return f
end

local function asyncFn(fn)
   return function(...)
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