local type Event = debug.HookEvent
local type Report = {string:{string:{Event}}}

local profiler <const> = {
	Report = Report,
}

local function defaultTable(): any
	return setmetatable({}, {
		__index = function(self: table, key: any): any
			local t = {}
			rawset(self, key, t)
			return t
		end
	})
end

local started = false
local currentReport: Report
function profiler.start()
	started = true
	currentReport = setmetatable({}, {
		__index = function(self: table, key: string): {string:{Event}}
			local t = defaultTable() as {string:{Event}}
			rawset(self, key, t)
			return t
		end
	})
	debug.sethook(function(event: Event)
		local info <const> = debug.getinfo(2);
		if info.source and info.name then
			table.insert(currentReport[info.source][info.name], event)
		end
	end, "cr")
end

function profiler.stop(): Report
	assert(started)
	started = false
	debug.sethook(nil)
	return currentReport
end

return profiler
