local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local debug = _tl_compat and _tl_compat.debug or debug; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table






local resume, yield, running, create, status =
coroutine.resume, coroutine.yield, coroutine.running, coroutine.create, coroutine.status

local isyieldable = coroutine.isyieldable or function() return false end

local function safeYield(...)
   if isyieldable() then
      return yield(...)
   end
end

local Event = {}




local Worker = {}


local WorkerPool = {}
local Anchor = {}
local Internal = {Worker = {}, EventLoop = {}, }














local EventLoop = {}


local externalThreads = {}
local eventLoops = {}
local workers = {}

local ev = {
   Event = Event,
   Worker = Worker,
   EventLoop = EventLoop,
}

local function stepThread(t, ...)
   if not resume(t, ...) then
      error("error in coroutine: " .. debug.traceback(t), 2)
   end
end

local function tick(t)
   stepThread(t)
   yield()
end

local function getRunningEventLoop(msg)
   local t = running()
   local loop = eventLoops[t]
   if not loop then
      error(string.format("%s: not running in an event loop", msg), 3)
   end
   return loop
end

local function hasWorkers(workerPools)
   return next(workerPools[true]) ~= nil or
   next(workerPools[false]) ~= nil
end

function ev.queue(t, ...)
   local q
   if type(t) == "thread" then
      local loop = eventLoops[t]
      if not loop then
         error("Cannot queue event: " .. tostring(t) .. " is not an event loop", 2)
      end
      q = loop.events
   else
      local loop = getRunningEventLoop("Cannot queue event")
      q = loop.events
      table.insert(q, t)
   end
   for i = 1, select("#", ...) do
      table.insert(q, (select(i, ...)))
   end
   safeYield()
end

function ev.anchor(t, ...)
   local a
   if type(t) == "thread" then
      local loop = eventLoops[t]
      if not loop then
         error("Cannot create anchor: " .. tostring(t) .. " is not an event loop")
      end
      a = loop.anchors
   else
      local loop = getRunningEventLoop("Cannot create anchor")
      a = loop.anchors
      table.insert(a, t)
   end
   for i = 1, select("#", ...) do
      table.insert(a, (select(i, ...)))
   end
   safeYield()
end

local function doWork(loop)
   local active = loop.activePool
   local src, dest = loop.pools[active], loop.pools[not active]
   loop.activePool = not active

   for handle, worker in pairs(src) do
      src[handle] = nil
      if status(worker) ~= "dead" then
         dest[handle] = worker
         stepThread(worker, loop.thread)
      end
      yield()
   end
end

local function isAnchored(anchors)
   for k, anchor in pairs(anchors) do
      if anchor() then
         return true
      else
         anchors[k] = nil
      end
   end
   return false
end

local function findEvent(events, kinds)
   for i, event in ipairs(events) do
      if kinds[event.kind] then
         return i
      end
   end
end

function ev.poll(...)
   local kinds = {}
   if select("#", ...) > 0 then
      for i = 1, select("#", ...) do
         kinds[select(i, ...)] = true
      end
   else
      setmetatable(kinds, { __index = function() return true end })
   end

   return function()
      local loop = getRunningEventLoop("Unable to poll")
      repeat doWork(loop)

      until not hasWorkers(loop.pools) or
findEvent(loop.events, kinds)
      do
         local idx = findEvent(loop.events, kinds)
         if idx then
            return table.remove(loop.events, idx)
         end
      end

      repeat yield(); doWork(loop)

      until not isAnchored(loop.anchors) or
findEvent(loop.events, kinds)
      local idx = findEvent(loop.events, kinds)
      if idx then
         return table.remove(loop.events, idx)
      end
   end
end

function ev.worker(t, f)
   local loop

   local func
   if type(t) == "thread" then
      loop = eventLoops[t]
      if not loop then
         error("Cannot create worker: " .. tostring(t) .. " is not an event loop", 2)
      end
      func = f
   else
      loop = getRunningEventLoop("Cannot create worker")
      func = t
      if f then
         error("Expected only 1 function argument when 2 were provided", 2)
      end
   end

   local handle = setmetatable({}, { __index = Worker })
   local workerThread = create(func)
   loop.pools[not loop.activePool][handle] = workerThread
   workers[handle] = {
      loop = loop,
      thread = workerThread,
   }
   return handle
end

function ev.wait()
   yield()
end

function Worker:isAlive()
   return status(workers[self].thread) ~= "dead"
end

function Worker:join()
   getRunningEventLoop("Unable to join worker")
   local t = workers[self].thread
   while t and status(t) ~= "dead" do
      tick(t)
   end
end

function Worker:kill()
   local internalHandle = workers[self]
   local loop = internalHandle.loop
   loop.pools[true][self] = nil
   loop.pools[false][self] = nil
   safeYield()
end

local function createLoop(f)
   return create(function()
      local eventQueue = {}
      local workerPools = {
         [true] = {},
         [false] = {},
      }
      local anchors = {}
      local mainThread = create(f)
      local loop = {
         thread = mainThread,
         pools = workerPools,
         activePool = true,
         events = eventQueue,
         anchors = anchors,
      }
      eventLoops[mainThread] = loop

      while status(mainThread) ~= "dead" do
         local ok, err = resume(mainThread)
         if not ok then
            error("error in main thread: " .. tostring(err) .. "\n" .. debug.traceback(mainThread), 2)
         end
         yield()
         if hasWorkers(workerPools) then
            doWork(loop)
         end
      end

      while hasWorkers(workerPools) do
         doWork(loop)
      end

      eventLoops[mainThread] = nil
   end)
end

function EventLoop:step()
   local t = rawget(externalThreads, self)
   stepThread(t)
end

function EventLoop:run()
   local t = rawget(externalThreads, self)
   while status(t) ~= "dead" do
      stepThread(t)
   end
end

local uv = vim.loop

function EventLoop:asyncRun(interval)
   local t = rawget(externalThreads, self)
   local timer = uv.new_timer()
   local function step()
      if status(t) ~= "dead" then
         local ok, err = resume(t)
         if not ok then
            error("Error in event loop: " .. tostring(err) .. "\n" .. debug.traceback(t))
         end
      end
   end
   timer:start(interval or 500, 0, vim.schedule_wrap(function()
      if status(t) ~= "dead" then
         step()
      elseif not timer:is_closing() then
         timer:stop()
         timer:close()
      end
   end))
   return timer
end

function EventLoop:isAlive()
   local t = rawget(externalThreads, self)
   return status(t) ~= "dead"
end

function ev.loop(f)
   local loop = setmetatable({}, { __index = EventLoop })
   externalThreads[loop] = createLoop(f)
   return loop
end

return ev