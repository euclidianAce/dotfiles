local wibox = require "wibox"
local awful = require "awful"
local naughty = require "naughty"

local textbox = wibox.widget.textbox()

local function prompt_test()
	awful.prompt.run {
		prompt = "<b>Echo: </b>",
		text = "Default Text",
		textbox = textbox,
		exe_callback = function(input)
			if not input or #input == 0 then return end
			naughty.notify{text = "Input was: " .. input}
		end
	}
end

--[[
local launcher_widget = wibox.wibox{
	width = 600,
	height = 100,
	x = 100,
	y = 100,
	widget = textbox,
}
--]]
return prompt_test
