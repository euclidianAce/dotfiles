local naughty = require "naughty"
local wibox = require "wibox"
local awful = require "awful"
local beautiful = require "beautiful"
local gears = require "gears"
local gio = require "lgi".Gio
local async = require "async"

-- check if battery exists
if not gears.filesystem.file_readable "/sys/class/power_supply/BAT0/charge_now"
	or not gears.filesystem.file_readable "/sys/class/power_supply/BAT0/charge_full"
then
	return wibox.widget.textbox("")
end

local function p(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring((select(i, ...)))
	end
	naughty.notify { title = "dbg", text = table.concat(t, "\n") }
end

local charge_now_path = "/sys/class/power_supply/BAT0/charge_now"
local charge_full_path = "/sys/class/power_supply/BAT0/charge_full"

local bar = wibox.widget.progressbar()
local text = wibox.widget.textbox()

local function updater()
	local now = tonumber(async.readAll(charge_now_path)) or 0
	local full = tonumber(async.readAll(charge_full_path)) or 1
	bar:set_value(now / full)
	text:set_text(tostring(math.floor(now * 100 / full)) .. "%")
end

local timer = gears.timer {
	timeout = 20,
	autostart = true,
	call_now = true,
	callback = function()
		local co = coroutine.create(updater)
		gears.timer.delayed_call(function()
			coroutine.resume(co)
		end)
	end,
}

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
		shape = function(cr, _, _)
			return gears.shape.rounded_rect(cr, 30, 5)
		end,
		forced_width = 25,
	},
	{ widget = text }
}

return indicator
