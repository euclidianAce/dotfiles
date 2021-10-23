local Event = debug.HookEvent
local Report = {}

local profiler = {
   Report = Report,
}

local function defaultTable()
   return setmetatable({}, {
      __index = function(self, key)
         local t = {}
         rawset(self, key, t)
         return t
      end,
   })
end

local started = false
local currentReport
function profiler.start()
   started = true
   currentReport = setmetatable({}, {
      __index = function(self, key)
         local t = defaultTable()
         rawset(self, key, t)
         return t
      end,
   })
   debug.sethook(function(event)
      local info = debug.getinfo(2);
      if info.source and info.name then
         table.insert(currentReport[info.source][info.name], event)
      end
   end, "cr")
end

function profiler.stop()
   assert(started)
   started = false
   debug.sethook(nil)
   return currentReport
end

return profiler