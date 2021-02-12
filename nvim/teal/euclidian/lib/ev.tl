
-- A very simple event loop/coroutine scheduler
--   - very simple in that it provides no non-blocking io facilities and
--     completely relies on the worker threads being well behaved
--     and yielding during their down time

local resume <const>, yield <const>, running <const>, create <const>, status <const>
	= coroutine.resume, coroutine.yield, coroutine.running, coroutine.create, coroutine.status

local isyieldable <const> = coroutine.isyieldable or function(): boolean return false end

local function safeYield(...: any): any...
	if isyieldable() then
		return yield(...)
	end
end

local record Event
	{any}
	kind: string
end

local record Worker
end

local type WorkerPool = {Worker:thread}
local type Anchor = function(): boolean
local record Internal
	record Worker
		loop: Internal.EventLoop
		thread: thread
	end
	record EventLoop
		activePool: boolean
		pools: {boolean:WorkerPool}
		anchors: {Anchor}
		events: {Event}
		thread: thread
	end
end

local record EventLoop
end

local externalThreads <const>: {EventLoop:thread} = {}
local eventLoops <const>: {thread:Internal.EventLoop} = {}
local workers <const>: {Worker:Internal.Worker} = {}

local ev <const> = {
	Event = Event,
	Worker = Worker,
	EventLoop = EventLoop,
}

local function stepThread(t: thread)
	if not resume(t) then
		error("error in coroutine: " .. debug.traceback(t), 2)
	end
end

local function tick(t: thread)
	stepThread(t)
	yield()
end

local function getRunningEventLoop(msg: string): Internal.EventLoop
	local t <const> = running()
	local loop <const> = eventLoops[t]
	if not loop then
		error(string.format("%s: not running in an event loop", msg), 3)
	end
	return loop
end

local function hasWorkers(workerPools: {boolean:WorkerPool}): boolean
	return next(workerPools[true]) ~= nil
		or next(workerPools[false]) ~= nil
end

function ev.queue(t: thread | Event, ...: Event)
	local q: {Event}
	if t is thread then
		local loop <const> = eventLoops[t]
		if not loop then
			error("Cannot queue event: " .. tostring(t) .. " is not an event loop", 2)
		end
		q = loop.events
	else
		local loop <const> = getRunningEventLoop("Cannot queue event")
		q = loop.events
		table.insert(q, t)
	end
	for i = 1, select("#", ...) do
		table.insert(q, (select(i, ...)))
	end
	safeYield()
end

function ev.anchor(t: thread | Anchor, ...: Anchor)
	local a: {Anchor}
	if t is thread then
		local loop <const> = eventLoops[t]
		if not loop then
			error("Cannot create anchor: " .. tostring(t) .. " is not an event loop")
		end
		a = loop.anchors
	else
		local loop <const> = getRunningEventLoop("Cannot create anchor")
		a = loop.anchors
		table.insert(a, t)
	end
	for i = 1, select("#", ...) do
		table.insert(a, (select(i, ...)))
	end
	safeYield()
end

local function doWork(loop: Internal.EventLoop)
	local active = loop.activePool
	local src <const>, dest <const> = loop.pools[active], loop.pools[not active]
	loop.activePool = not active

	for handle, worker in pairs(src) do
		src[handle] = nil
		if status(worker) ~= "dead" then
			dest[handle] = worker
			stepThread(worker)
		end
		yield()
	end
end

local function isAnchored(anchors: {number:Anchor}): boolean
	for k, anchor in pairs(anchors) do
		if anchor() then
			return true
		else
			anchors[k] = nil
		end
	end
	return false
end

local function findEvent(events: {Event}, kinds: {string:boolean}): number
	for i, event in ipairs(events) do
		if kinds[event.kind] then
			return i
		end
	end
end

function ev.poll(...: string): function(): Event
	local kinds <const>: {string:boolean} = {}
	if select("#", ...) > 0 then
		for i = 1, select("#", ...) do
			kinds[select(i, ...)] = true
		end
	else
		setmetatable(kinds, { __index = function(): boolean return true end })
	end

	local loop <const> = getRunningEventLoop("Unable to poll")

	return function(): Event
		repeat doWork(loop)
		until not hasWorkers(loop.pools)
			or findEvent(loop.events, kinds) as boolean

		do
			local idx <const> = findEvent(loop.events, kinds)
			if idx then
				return table.remove(loop.events, idx)
			end
		end

		repeat yield() doWork(loop)
		until not isAnchored(loop.anchors)
			or findEvent(loop.events, kinds) as boolean

		local idx <const> = findEvent(loop.events, kinds)
		if idx then
			return table.remove(loop.events, idx)
		end
	end
end

function ev.worker(t: function | thread, f: function): Worker
	local loop: Internal.EventLoop

	local func: function
	if t is thread then
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

	local handle <const> = setmetatable({}, { __index = Worker }) as Worker
	local workerThread <const> = create(func)
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

function Worker:isAlive(): boolean
	return status(workers[self].thread) ~= "dead"
end

function Worker:join()
	getRunningEventLoop("Unable to join worker")
	local t <const> = workers[self].thread
	while t and status(t) ~= "dead" do
		tick(t)
	end
end

function Worker:kill()
	local internalHandle <const> = workers[self]
	local loop <const> = internalHandle.loop
	loop.pools[true][self] = nil
	loop.pools[false][self] = nil
	safeYield()
end

local function createLoop(f: function): thread
	return create(function()
		local eventQueue <const>: {Event} = {}
		local workerPools <const>: {boolean:WorkerPool} = {
			[true] = {} as WorkerPool,
			[false] = {} as WorkerPool,
		}
		local anchors <const>: {Anchor} = {}
		local mainThread <const> = create(f)
		local loop <const> = {
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
	local t <const> = rawget(externalThreads, self)
	stepThread(t)
end

function EventLoop:run()
	local t <const> = rawget(externalThreads, self)
	while status(t) ~= "dead" do
		stepThread(t)
	end
end

--- Spawns a uv.new_timer to tick the eventloop every msInterval
local uv <const> = vim.loop
function EventLoop:asyncRun(msInterval: number, delay: number): uv.Timer
	local t <const> = rawget(externalThreads, self)
	local timer = uv.new_timer()
	local function step()
		if status(t) ~= "dead" then
			local ok, err = resume(t)
			if not ok then
				error("error in event loop: " .. tostring(err) .. "\n" .. debug.traceback(t))
			end
		end
	end
	timer:start(delay or 0, msInterval or 500, vim.schedule_wrap(function()
		if status(t) ~= "dead" then
			step()
		elseif not timer:is_closing() then
			timer:stop()
			timer:close()
		end
	end))
	return timer
end

function EventLoop:isAlive(): boolean
	local t <const> = rawget(externalThreads, self)
	return status(t) ~= "dead"
end

function ev.loop(f: function): EventLoop
	local loop <const>: EventLoop = setmetatable({}, { __index = EventLoop })
	externalThreads[loop] = createLoop(f)
	return loop
end

return ev

