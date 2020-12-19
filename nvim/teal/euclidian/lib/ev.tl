
global unpack: function<T>({T}): T...
local unpack <const> = table.unpack or unpack

local wrap <const>, resume <const>, yield <const>, running <const>, create <const>, status <const>
	= coroutine.wrap, coroutine.resume, coroutine.yield, coroutine.running, coroutine.create, coroutine.status

local record ev
	record Event--<T> -- maybe make this generic somehow
		kind: string
		data: {any}--{T}
	end
	record EventLoop--<T>
		isAlive: function(): boolean
		step: function()
		exec: function()
		nextEvent: function(): string, {any}--{T}
	end
	record Worker
		isDone: function(Worker): boolean
		join: function(Worker)
	end

	loop: function(f: function): EventLoop
end

local Event <const> = ev.Event
local EventLoop <const> = ev.EventLoop

local rawQueues <const>: {thread:{Event}} = setmetatable({}, {
	__mode = "v",
	__index = function(self: {thread:{Event}}, key: thread): {Event}
		local t: {Event} = {}
		rawset(self, key, t)
		return t
	end
})

local threads <const>: {EventLoop:thread} = setmetatable({}, { __mode = "k" })

-- 5.1 compat
local isyieldable <const> = coroutine.isyieldable or function(): boolean return false end

local _queue <const> = {}
function ev.queue(kind: string, ...: any)
	if isyieldable() then
		-- Prefer yielding so that background tasks in the event loop can happen
		yield(_queue, {kind = kind, data = {...}})
	elseif running() then
		-- If we can't yield (or can't guarantee that we can) then
		-- add it to the array that can be checked by the event
		-- loop without interrupting it (For C yield boundaries)
		table.insert(rawQueues[running()], {kind = kind, data = {...}})
	else
		-- This shouldn't happen as running() should never be nil
		error("unable to queue event, not running in a coroutine", 2)
	end
end
function ev.queueForThread(t: thread, kind: string, ...: any)
	table.insert(rawQueues[t], {kind = kind, data = {...}})
end
function ev.queueForEventLoop(el: EventLoop, kind: string, ...: any)
	local t = threads[el]
	if t then
		table.insert(rawQueues[t], {kind = kind, data = {...}})
	end
end

local record YieldKind
end
local record YieldResult
	fromThread: thread
	data: any
end

local function evYield(kind: YieldKind, data: any): any...
	return yield(kind, {
		fromThread = running(),
		data = data,
	})
end

local _poll <const>: YieldKind = {}
function ev.poll(): string, any...
	return evYield(_poll) as (string, any)
end

local _worker <const>: YieldKind = {}
function ev.worker(f: function): ev.Worker
	return evYield(_worker, create(f)) as ev.Worker
end

local _wait <const>: YieldKind = {}
function ev.wait()
	evYield(_wait)
end
function ev.waitUntil(pred: function(): boolean)
	repeat evYield(_wait)
	until pred()
end
function ev.waitWhile(pred: function(): boolean)
	while pred() do
		evYield(_wait)
	end
end

local _step <const>: YieldKind = {}
local function stepResume(t: thread, ...: any): {any}
	evYield(_step)
	return {select(2, assert(resume(t, ...)))} end

local _getWorker <const>: YieldKind = {}
function ev.Worker:isDone(): boolean
	return evYield(_getWorker, self) == nil
end
function ev.Worker:join()
	ev.waitUntil(function(): boolean
		return self:isDone()
	end)
end
local workerMetatable <const> = { __index = ev.Worker }

local function loop(f: function): thread
	return create(function()
		local localQueue <const>: {Event} = {}
		local localWorkers <const>: {ev.Worker:thread} = {}

		local doWork: function(): boolean

		local mainThread <const> = create(f)

		local function flushRawQueue()
			local last <const> = #localQueue -- make sure the events get queued in the correct order
			local numEvs <const> = #rawQueues[mainThread]
			for i = 1, numEvs do
				localQueue[last + i] = rawQueues[mainThread][i]
			end
			rawQueues[mainThread] = {}
		end
		local function newWorkerHandle(t: thread): ev.Worker
			local handle <const>: ev.Worker = setmetatable({}, workerMetatable)
			localWorkers[handle] = t
			return handle
		end

		local function respondToYield(kind: YieldKind, res: YieldResult)
			yield(_step)
			if kind == _poll then
				if res.fromThread == mainThread then
					local workDone: boolean
					repeat workDone = doWork() -- do work until
					until #localQueue > 0 -- an event is generated
						or #localWorkers == 0 -- or there is no more work
				end
			elseif kind == _queue then
				table.insert(localQueue, res.data as Event)
			elseif kind == _wait then
				flushRawQueue()
			elseif kind == _worker then
				local handle <const> = newWorkerHandle(res.data as thread)
				stepResume(res.fromThread, handle)
			elseif kind == _getWorker then
				stepResume(res.fromThread, localWorkers[res.data as ev.Worker])
			end
			doWork()
		end

		doWork = function(): boolean
			flushRawQueue()

			local workDone = false
			for handle, worker in pairs(localWorkers) do
				if status(worker) == "dead" then
					localWorkers[handle] = nil
				else
					workDone = true
					local res = stepResume(worker)
					respondToYield(res[1] as YieldKind, res[2] as YieldResult)
				end
			end
			return workDone
		end

		local function grabNextEvent(): Event
			return table.remove(localQueue, 1)
		end

		local function yieldEvent(e: Event)
			if e then
				yield(e.kind, unpack(e.data))
			end
		end

		local res: {any}
		local nextEv: Event
		while status(mainThread) ~= "dead" do
			yield(_step)
			if nextEv then
				res = stepResume(mainThread, nextEv.kind, unpack(nextEv.data))
			else
				res = stepResume(mainThread)
			end
			nextEv = grabNextEvent()
			respondToYield(res[1] as YieldKind, res[2] as YieldResult)
			yield(_step)
			yieldEvent(nextEv)
			if #localWorkers > 0 then
				doWork()
				yield(_step)
			end
		end

		-- main thread is dead, long live the main thread
		-- let the workers finish and yield their events
		while #localWorkers > 0 do
			doWork()
			flushRawQueue()
			if #localQueue > 0 then
				yieldEvent(grabNextEvent())
			end
			yield(_step)
		end

		-- after the workers are finished, flush the queue
		flushRawQueue()
		while #localQueue > 0 do
			yield(_step)
			yieldEvent(grabNextEvent())
		end
	end)
end

--- Returns the raw coroutine that is used to power the event loop
function EventLoop:thread(): thread
	return threads[self]
end

function EventLoop:step()
	assert(resume(threads[self]))
end

function EventLoop:exec()
	local t <const> = threads[self]
	while status(t) ~= "dead" do
		assert(resume(t))
	end
end

function EventLoop:isAlive(): boolean
	return status(threads[self]) ~= "dead"
end

function EventLoop:nextEvent(): string, {any}
	local l <const> = threads[self]
	local evKind, evData: any, {any}
	repeat
		evKind, evData = select(2, assert(resume(l))) as (table|string, {any})
	until not evKind is table
	return evKind as string, evData
end

function EventLoop:events(): function(): string, {any}
	return function(): string, {any}
		if self:isAlive() then
			return self:nextEvent()
		end
	end
end

local evMetatable <const> = { __index = EventLoop }
local function newEventLoop(f: function): EventLoop
	local el <const>: EventLoop = setmetatable({}, evMetatable)
	local l <const> = loop(f)
	threads[el] = l
	return el
end

ev.loop = newEventLoop

return ev

