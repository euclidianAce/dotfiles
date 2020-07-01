local wibox = require "wibox"
local awful = require "awful"
local gears = require "gears"
local beautiful = require "beautiful"

local config = require("customWidgets.wificonfig")
local interface = config.interface
local cmd = ("wpa_cli -i %s list_networks | grep CURRENT"):format(interface)
local badText = " Not Connected "
local text = wibox.widget.textbox(badText)


local wifi = wibox.widget {
	layout = wibox.layout.align.horizontal,
	{widget = awful.widget.watch(("sh -c '%s'"):format(cmd), 5, function(widget, stdout)
		
		local start = stdout:find("\t")
		if not start then
			widget:set_text(badText)
			return
		else
			start = start + 1
		end

		local finish = stdout:find("\t", start)
		if not finish then
			widget:set_text(badText)
			return
		else
			finish = finish - 1
		end

		widget:set_text(stdout:sub(start, finish))
	end, text)}
}


return wifi
