local awful = require "awful"
local wibox = require "wibox"
local naughty = require "naughty"

-- TODO find a nice little icon

local textbox = wibox.widget.textbox()
local function updateVolumeText(after)
	awful.spawn.easy_async("amixer sget Master", function(stdout, stderr, reason, exit_code)
		if exit_code ~= 0 then
			textbox:set_text("volume: ?? %")
		end
		local p = stdout:match("%d+%s*%%")
		if p then
			textbox:set_text("volume: " .. p)
		else
			textbox:set_text("volume: ?? %")
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
		updateVolumeText()
	end)
end

local function muteToggle()
	awful.spawn.easy_async("amixer sset Master toggle", function()
		updateVolumeText()
	end)
end

updateVolumeText()

local delta = 10

return {
	widget = textbox,
	keys = {
		awful.key({}, "XF86AudioRaiseVolume", function() addVolume(delta) end),
		awful.key({}, "XF86AudioLowerVolume", function() addVolume(-delta) end),
		awful.key({}, "XF86AudioMute", function() muteToggle() end),
	},
}
