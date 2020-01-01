local awful = require "awful"
local wibox = require "wibox"
local gears = require "gears"

local cpugraph = wibox.widget.graph()
cpugraph.forced_width = 36
ramgraph.step_width = 6
ramgraph.max_value = 100
local cpuclock = awful.widget.watch('top -b -n 1 | grep %Cpu(s)', 10, function(_, stdout)
	local percent = stdout:match("%Cpu(s):%s+(%d+)")
	percent = tonumber(percent)
	cpugraph:add_value(percent)
end)

local cpuwidget = wibox.widget {
	layout = wibox.layout.align.horizontal,
	{widget = cpugraph},
	{widget = cpuclock},
}

return cpuwidget
