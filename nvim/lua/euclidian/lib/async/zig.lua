





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

local function internalResume(frame, ...)
   if isDead(frame) then
      error("Resumed an async function which already returned", 3)
   end

   local ok, val, fn =
coroutine.resume(frame._t, ...)
   if not ok then
      error(val, 3)
   end

   if isDead(frame) then
      frame._v = val
      if frame._awaiter then
         local awaiterok, awaiterval = coroutine.resume(frame._awaiter)
         if not awaiterok then
            error(awaiterval, 3)
         end
      end
   end

   if val == suspendBlock then
      return fn(frame)
   end
end

local function resume(frame)
   internalResume(frame)
end

local function await(frame)
   if not isDead(frame) then
      assert(frame._awaiter == nil, "async function awaited twice")
      frame._awaiter = coroutine.running()
      coroutine.yield()
      assert(isDead(frame), "awaiting function resumed")
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
   if not isDead(frame) then
      error("Function suspended in a nosuspend", 2)
   end
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