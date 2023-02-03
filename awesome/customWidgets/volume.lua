local awful = require "awful"
local wibox = require "wibox"
local naughty = require "naughty"
local beautiful = require "beautiful"

-- TODO find a nice little icon

local widget = wibox.widget {
	widget = wibox.container.arcchart,
	value = 0,
	min_value = 0,
	max_value = 100,
	thickness = 3,
	colors = { beautiful.bg_focus },
	bg = beautiful.bg_normal,
}

local function updateVisual(after)
	awful.spawn.easy_async("amixer sget Master", function(stdout, stderr, reason, exit_code)
		if exit_code ~= 0 then
			return
		end
		local p = tonumber(stdout:match("(%d+)%s*%%"))
		if p then
			widget.value = p
		end
		if after then
			gears.timer.delayed_call(after)
		end
	end)
end

local wav = "/home/corey/.config/awesome/pop.wav"
local function pop()
	awful.spawn.easy_async("aplay " .. wav, function() end)
end

local function addVolume(delta_percent)
	awful.spawn.easy_async(("amixer set Master %d%%%s"):format(math.abs(delta_percent), delta_percent >= 0 and "+" or "-"), function()
		pop()
		updateVisual()
	end)
end

local function muteToggle()
	awful.spawn.easy_async("amixer sset Master toggle", function()
		updateVisual()
	end)
end

updateVisual()

local delta = 10

return {
	widget = widget,
	keys = {
		awful.key({}, "XF86AudioRaiseVolume", function() addVolume(delta) end),
		awful.key({}, "XF86AudioLowerVolume", function() addVolume(-delta) end),
		awful.key({}, "XF86AudioMute", function() muteToggle() end),
	},
}
