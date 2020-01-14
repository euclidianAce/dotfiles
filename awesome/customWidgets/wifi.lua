local wibox = require "wibox"
local awful = require "awful"
local gears = require "gears"
local beautiful = require "beautiful"

local interface = "wlp2s0"
local cmd = ("wpa_cli -i %s list_networks | grep CURRENT"):format(interface)


local icon_path = "../icons/"
local wifi_good_icon = icon_path .. "wifi.svg"
local wifi_bad_icon = icon_path .. "wifi-off.svg"

local wifi_icon_widget = wibox.widget.imagebox()

local wifi = wibox.widget {
	layout = wibox.layout.align.horizontal,
	{widget = wifi_icon_widget},
	{widget = awful.widget.watch(("sh -c '%s'"):format(cmd), 3, function(widget, stdout)
		local start = stdout:find("\t")
		if not start then
			widget:set_text(" Not Connected ")
		else
			start = start + 1
		end
		local finish = stdout:find("\t", start)-1
		widget:set_text(stdout:sub(start, finish))
	end)}
}


return wifi
