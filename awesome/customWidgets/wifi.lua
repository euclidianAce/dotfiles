local wibox = require "wibox"
local awful = require "awful"
local gears = require "gears"
local beautiful = require "beautiful"

local icon_path = "../icons/"
local wifi_good_icon = icon_path .. "wifi.svg"
local wifi_bad_icon = icon_path .. "wifi-off.svg"

local wifi_icon_widget = wibox.widget.imagebox()

local wifi = wibox.widget {
	layout = wibox.layout.align.horizontal,
	{widget = wifi_icon_widget},
	{widget = awful.widget.watch("bash -c 'wpa_cli list_networks | grep CURRENT'", 3, function(widget, stdout)
		widget:set_text(stdout.." ")
		local start = stdout:find("\t")+1
		local finish = stdout:find("\t", start)-1
		widget:set_text(stdout:sub(start, finish))
	end)}
}


return wifi
