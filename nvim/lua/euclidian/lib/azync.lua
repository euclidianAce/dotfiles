




local Frame = {}




local Packed = {}




local frameCache = setmetatable({}, { __mode = "k" })
local values = setmetatable({}, { __mode = "k" })
local status = coroutine.status

local suspendBlock = {}
local function suspend(fn)
   coroutine.yield(fn and suspendBlock, fn)
end

local function isDead(frame)
   if type(frame) ~= "table" then
      print(debug.getinfo(2))
      error("???")
   end
   return status(frame._t) == "dead"
end

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

local scheduledInternalResume = vim.schedule_wrap(internalResume)

local function resume(frame)
   internalResume(frame)
end

local function resumeSchedule(frame)
   scheduledInternalResume(frame)
end

local function currentFrame()
   local co = coroutine.running()
   return frameCache[co]
end

local function unpackFrameResult(frame)
   return (unpack)(
   values[frame], 1, values[frame].n)
end

local function await(frame)
   if not isDead(frame) then
      assert(frame._awaiter == nil, "async function awaited twice")
      frame._awaiter = assert(currentFrame(), "Not running in an async function")
      coroutine.yield()
      assert(isDead(frame), "awaiting function resumed")
   end
   return unpackFrameResult(frame)
end

local function wrapCallable(fn)
   if type(fn) ~= "function" then
      return function(...) return fn(...) end
   end
   return fn
end

local function nosuspend(fn, ...)
   local frame = { _t = coroutine.create(wrapCallable(fn)) }
   frameCache[frame._t] = frame
   internalResume(frame, ...)
   if not isDead(frame) then
      error("Function suspended in a nosuspend", 2)
   end
   return unpackFrameResult(frame)
end

local function async(fn, ...)
   local co = coroutine.create(wrapCallable(fn))
   local f = { _t = co }
   frameCache[co] = f
   internalResume(f, ...)
   return f
end

local function asyncSchedule(fn, ...)
   local co = coroutine.create(wrapCallable(fn))
   local f = { _t = co }
   frameCache[co] = f
   vim.schedule_wrap(internalResume)(f, ...)
   return f
end

local function asyncFn(fn)
   return function(...)
      return async(fn, ...)
   end
end

local function randomRange(n)
   local range = {}
   for i = 1, n do
      range[i] = i
   end
   for i = n, 1, -1 do
      local j = math.random(1, i)
      range[i], range[j] = range[j], range[i]
   end
   local i = 0
   return function()
      i = i + 1
      return range[i]
   end
end

local function selectFrame(...)
   local current = assert(currentFrame(), "Not running in an async function")
   local frames = { ... }

   local nframes = #frames


   for i in randomRange(nframes) do
      assert(not frames[i]._awaiter, "async function awaited twice (in select)")
      if isDead(frames[i]) then
         return frames[i]
      end
   end


   for i = 1, nframes do
      frames[i]._awaiter = current
   end
   coroutine.yield()

   local idx
   for i in randomRange(nframes) do
      if isDead(frames[i]) then
         idx = i
         break
      end
   end
   assert(idx, "selecting function resumed")

   for i = 1, nframes do
      frames[i]._awaiter = nil
   end
   return frames[idx]
end

local function selectAwait(...)
   local f = selectFrame(...)
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