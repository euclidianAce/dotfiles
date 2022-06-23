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

local menu
local menuitems = {}

local fh = io.open(config.wpaSupplicantConfig or "/etc/wpa_supplicant.conf", "r")
if fh then
	local idx = -1
	local function nextLine()
		while true do
			local ln = fh:read("*l")
			if not ln then return end
			local networkName = ln:match("%s*ssid=\"(.*)\"%s*$")
			if networkName then
				idx = idx + 1
				return networkName, idx
			end
		end
	end
	for name, num in nextLine do
		table.insert(menuitems, {
			name,
			function()
				naughty.notify{
					title = "selected:",
					text = name, --wpafmt:format("select_network " .. num)
				}

				-- TODO: im like 90% sure theres a way to asynchronously spawn a shell with awesome,
				-- but this shouldn't block for like any amount of time so :P
				os.execute(wpafmt:format("select_network " .. num))
			end
		})
	end
	fh:close()
	menu = awful.menu{
		items = menuitems,
	}
end


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

if menu then
	wifi:buttons(gears.table.join(
		awful.button({}, 1, function()
			menu:toggle()
		end)
	))
end

return wifi
