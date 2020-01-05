local awful = require "awful"
local wibox = require "wibox"
local beautiful = require "beautiful"

local cpugraph = wibox.widget.graph()
cpugraph.forced_width = 36
cpugraph.step_width = 6
cpugraph.max_value = 100
cpugraph.color = beautiful.bg_focus
local cpuclock = awful.widget.watch({'sh', '-c', 'top -b -n 1 | grep %Cpu'}, 10, function(widget, stdout)
	local percent = stdout:match("%Cpu%(s%):%s+(%d+)")
	percent = tonumber(percent)
	widget:add_value(percent)
end, cpugraph)


return cpugraph
