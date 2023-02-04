local naughty = require "naughty"
local wibox = require "wibox"
local awful = require "awful"
local beautiful = require "beautiful"
local gears = require "gears"
local gio = require "lgi".Gio

local function p(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring((select(i, ...)))
	end
	naughty.notify { title = "p", text = table.concat(t, "\n") }
end

local function readAll(filename)
	local to_resume = coroutine.running()
	gio.Async.start(function()
		local file = gio.File.new_for_path(filename)
		local info, err = file:async_query_info("standard::size", "NONE")
		if not info then
			gears.timer.delayed_call(function()
				coroutine.resume(to_resume, nil, err)
			end)
			return
		end
		local stream = file:async_read()
		local bytes = stream:async_read_bytes(info:get_size())
		stream:async_close()
		gears.timer.delayed_call(function()
			coroutine.resume(to_resume, bytes.data)
		end)
	end)()
	return coroutine.yield()
end

local charge_now_path = "/sys/class/power_supply/BAT0/charge_now"
local charge_full_path = "/sys/class/power_supply/BAT0/charge_full"

local function updater()
	local now = tonumber(readAll(charge_now_path)) or 0
	local full = tonumber(readAll(charge_full_path)) or 1
	widget:set_value(charge_now / charge_full)
	text:set_text(math.floor(charge_now * 100 / charge_full) .. "%")
end

-- check if battery exists
if not gears.filesystem.file_readable "/sys/class/power_supply/BAT0/charge_now"
	or not gears.filesystem.file_readable "/sys/class/power_supply/BAT0/charge_full"
then
	return wibox.widget.textbox("")
end

local bar = wibox.widget.progressbar()
local text = wibox.widget.textbox()
local timer = gears.timer {
	timeout = 60,
	autostart = true,
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
