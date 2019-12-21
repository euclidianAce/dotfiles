local awful = require "awful"
local wibox = require "wibox"
local gears = require "gears"


-- get total ram
local total do
	local f = io.popen("free | grep Mem:")
	total = f:read()
	f:close()
end
total = tonumber(total:match("Mem:%s+(%d+)"))

local ramgraph = wibox.widget.graph()
ramgraph.forced_width = 36
ramgraph.step_width = 6
ramgraph.max_value = total
local ramclock = awful.widget.watch("free | grep Mem:", 10, function(widget, stdout)
	local used = stdout:match("Mem:%s+%d+%s+(%d+)")
	used = tonumber(used)
	ramgraph:add_value(used)
end)

local ramwidget = wibox.widget {
	layout = wibox.layout.align.horizontal,
	{widget = ramgraph},
	{widget = ramclock},
}



return ramwidget
