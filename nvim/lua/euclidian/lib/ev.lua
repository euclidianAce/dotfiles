

local unpack = table.unpack or unpack

local wrap, resume, yield, running, create, status =
coroutine.wrap, coroutine.resume, coroutine.yield, coroutine.running, coroutine.create, coroutine.status

local ev = {Event = {}, EventLoop = {}, Worker = {}, }


















local Event = ev.Event
local EventLoop = ev.EventLoop

local rawQueues = setmetatable({}, {
   __mode = "v",
   __index = function(self, key)
      local t = {}
      rawset(self, key, t)
      return t
   end,
})

local threads = setmetatable({}, { __mode = "k" })


local isyieldable = coroutine.isyieldable or function()    return false end

local _queue = {}
function ev.queue(kind, ...)
   if isyieldable() then

      yield(_queue, { kind = kind, data = { ... } })
   elseif running() then



      table.insert(rawQueues[running()], { kind = kind, data = { ... } })
   else

      error("unable to queue event, not running in a coroutine", 2)
   end
end
function ev.queueForThread(t, kind, ...)
   table.insert(rawQueues[t], { kind = kind, data = { ... } })
end
function ev.queueForEventLoop(el, kind, ...)
   local t = threads[el]
   if t then
      table.insert(rawQueues[t], { kind = kind, data = { ... } })
   end
end

local YieldKind = {}

local YieldResult = {}




local function evYield(kind, data)
   return yield(kind, {
      fromThread = running(),
      data = data,
   })
end

local _poll = {}
function ev.poll()
   return evYield(_poll)
end

local _worker = {}
function ev.worker(f)
   return evYield(_worker, create(f))
end

local _wait = {}
function ev.wait()
   evYield(_wait)
end
function ev.waitUntil(pred)
   repeat       evYield(_wait)
   until pred()
end
function ev.waitWhile(pred)
   while pred() do
      evYield(_wait)
   end
end

local _step = {}
local function stepResume(t, ...)
   evYield(_step)
   return { select(2, assert(resume(t, ...))) } end

local _getWorker = {}
function ev.Worker:isDone()
   return evYield(_getWorker, self) == nil
end
function ev.Worker:join()
   ev.waitUntil(function()
      return self:isDone()
   end)
end
local workerMetatable = { __index = ev.Worker }

local function loop(f)
   return create(function()
      local localQueue = {}
      local localWorkers = {}

      local doWork

      local mainThread = create(f)

      local function flushRawQueue()
         local last = #localQueue
         local numEvs = #rawQueues[mainThread]
         for i = 1, numEvs do
            localQueue[last + i] = rawQueues[mainThread][i]
         end
         rawQueues[mainThread] = {}
      end
      local function newWorkerHandle(t)
         local handle = setmetatable({}, workerMetatable)
         localWorkers[handle] = t
         return handle
      end

      local function respondToYield(kind, res)
         yield(_step)
         if kind == _poll then
            if res.fromThread == mainThread then
               local workDone
               repeat                   workDone = doWork()
               until #localQueue > 0 or
                  #localWorkers == 0
            end
         elseif kind == _queue then
            table.insert(localQueue, res.data)
         elseif kind == _wait then
            flushRawQueue()
         elseif kind == _worker then
            local handle = newWorkerHandle(res.data)
            stepResume(res.fromThread, handle)
         elseif kind == _getWorker then
            stepResume(res.fromThread, localWorkers[res.data])
         end
         doWork()
      end

      doWork = function()
         flushRawQueue()

         local workDone = false
         for handle, worker in pairs(localWorkers) do
            if status(worker) == "dead" then
               localWorkers[handle] = nil
            else
               workDone = true
               local res = stepResume(worker)
               respondToYield(res[1], res[2])
            end
         end
         return workDone
      end

      local function grabNextEvent()
         return table.remove(localQueue, 1)
      end

      local function yieldEvent(e)
         if e then
            yield(e.kind, unpack(e.data))
         end
      end

      local res
      local nextEv
      while status(mainThread) ~= "dead" do
         yield(_step)
         if nextEv then
            res = stepResume(mainThread, nextEv.kind, unpack(nextEv.data))
         else
            res = stepResume(mainThread)
         end
         nextEv = grabNextEvent()
         respondToYield(res[1], res[2])
         yield(_step)
         yieldEvent(nextEv)
         if #localWorkers > 0 then
            doWork()
            yield(_step)
         end
      end



      while #localWorkers > 0 do
         doWork()
         flushRawQueue()
         if #localQueue > 0 then
            yieldEvent(grabNextEvent())
         end
         yield(_step)
      end


      flushRawQueue()
      while #localQueue > 0 do
         yield(_step)
         yieldEvent(grabNextEvent())
      end
   end)
end


function EventLoop:thread()
   return threads[self]
end

function EventLoop:step()
   assert(resume(threads[self]))
end

function EventLoop:exec()
   local t = threads[self]
   while status(t) ~= "dead" do
      assert(resume(t))
   end
end

function EventLoop:isAlive()
   return status(threads[self]) ~= "dead"
end

function EventLoop:nextEvent()
   local l = threads[self]
   local evKind, evData
   repeat
      evKind, evData = select(2, assert(resume(l)))
   until not (type(evKind) == "table")
   return evKind, evData
end

function EventLoop:events()
   return function()
      if self:isAlive() then
         return self:nextEvent()
      end
   end
end

local evMetatable = { __index = EventLoop }
local function newEventLoop(f)
   local el = setmetatable({}, evMetatable)
   local l = loop(f)
   threads[el] = l
   return el
end

ev.loop = newEventLoop

return ev
