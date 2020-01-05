local wibox = require "wibox"
local awful = require "awful"
local beautiful = require "beautiful"


local bar = wibox.widget.progressbar()
local text = wibox.widget.textbox("")
local watch = awful.widget.watch("", 60)

local indicator = wibox.widget {
	layout = wibox.layout.align.horizontal,
	wibox.widget {
		layout = wibox.layout.stack,
		{
			widget = bar,
			max_value = 1,
			value = 0,
			paddings = 1,
			border_width = 1,
			border_color = beautiful.border_color,
			shape = function(cr, w, h)
				gears.shape.rounded_rect(cr, w, 5)
			end,
			forced_width = 25,
		},
		{
			widget = text,
			text = ""
		}
	}
}


return indicator
