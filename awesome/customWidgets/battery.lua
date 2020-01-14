local wibox = require "wibox"
local awful = require "awful"
local beautiful = require "beautiful"
local gears = require "gears"

-- check if battery exists
do
	local f = io.open("/sys/class/power_supply/BAT0/charge_now", "r")
	if not f then
		return wibox.widget.textbox("")
	end
	f:close()
end


local bar = wibox.widget.progressbar()
local text = wibox.widget.textbox()
local watch = awful.widget.watch("cat /sys/class/power_supply/BAT0/charge_now && cat /sys/class/power_supply/BAT0/charge_full", 60, function(widget, stdout)
	local charge_now, charge_full = stdout:match("(%d+)%s+(%d+)")
	widget:set_value(charge_now / charge_full)
	text:set_text(math.floor(charge_now * 100 / charge_full) .. "%")
end, bar)

local indicator = wibox.widget {
	layout = wibox.layout.stack,
	{
		widget = bar,
		max_value = 1,
		value = 0,
		paddings = 1,
		border_width = 1,
		border_color = beautiful.border_color,
		color = beautiful.bg_focus,
		background_color = beautiful.border_normal,
		shape = function(cr, w, h) 
			return gears.shape.rounded_rect(cr, 30, 5)
		end,
		forced_width = 25,
	},
	{widget = text}
}



return indicator
