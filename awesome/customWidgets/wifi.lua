local wibox = require "wibox"
local awful = require "awful"
local gears = require "gears"
local beautiful = require "beautiful"
local naughty = require "naughty"

local hasConfig, config = pcall(require, "customWidgets.wificonfig")
if not hasConfig then
	return wibox.widget{}
end

local wpafmt = ("wpa_cli -i %s %%s"):format(config.interface)
local cmd = wpafmt:format("list_networks | grep CURRENT")
local badText = " Not Connected "
local text = wibox.widget.textbox(badText)

local menuitems = {}

local function readAllSync(filename)
	local fh, err = io.open(filename, "r")
	if not fh then
		return nil, err
	end
	local contents = fh:read("*a")
	fh:close()
	return contents
end

local toTry = {
	"/etc/wpa_supplicant.conf",
	config.wpaSupplicantConfig,
}

local configContents
do
	local errs = {}
	for _, v in ipairs(toTry) do
		local err
		configContents, err = readAllSync(v)
		if configContents then
			break
		end
		table.insert(errs, v .. ": " .. err)
	end

	if not configContents then
		naughty.notify {
			preset = naughty.config.presets.critical,
			title = "Wifi Widget Error",
			text = table.concat(errs, "\n"),
		}
		return wibox.widget.textbox("???")
	end
end

local zero_index = -1
for line in configContents:gmatch("[^\n]") do
	local networkName = line:match("%s*ssid=\"(.*)\"%s*$")
	if networkName then
		zero_index = zero_index + 1
		table.insert(menuitems, {
			name,
			function()
				naughty.notify{ text = "selected network: " .. name }
				awful.spawn.easy_async(wpafmt:format("select_network " .. num))
			end
		})
	end
end

local menu = awful.menu{
	items = menuitems,
}

local wifi = wibox.widget {
	layout = wibox.layout.align.horizontal,
	{
		widget = awful.widget.watch(
			("sh -c '%s'"):format(cmd),
			5,
			function(widget, stdout)
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
			end,
			text
		)
	}
}

wifi:buttons(gears.table.join(
	awful.button({}, 1, function()
		menu:toggle()
	end)
))

return wifi
