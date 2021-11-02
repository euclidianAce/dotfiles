-- {{{ Requires
-- Standard lib
local gears 		= require "gears"
local awful 		= require "awful"
			  require "awful.autofocus"

-- Widget lib
local wibox 		= require "wibox"

-- Theme lib
local beautiful		= require "beautiful"

-- Notification lib
local naughty 		= require "naughty"
local menubar 		= require "menubar"
local hotkeys_popup	= require("awful.hotkeys_popup").widget

-- Enable hotkeys help widget for vim and other things
			  require "awful.hotkeys_popup.keys"

-- }}}
-- {{{ Error handling from default rc.lua

-- Check for startup errors
if awesome.startup_errors then
	naughty.notify({ preset = naughty.config.presets.critical,
			 title  = "Errors during startup",
			 text   = awesome.startup_errors })
end

-- Handle runtime errors
do
	local in_error = false
	awesome.connect_signal("debug::error", function(err)
		-- Make sure function doesnt call itself
		if in_error then return end
		in_error = true

		naughty.notify({ preset = naughty.config.presets.critical,
		title  = "Error Occured",
		text   = tostring(err) })
	end)
end

-- }}}
-- {{{ Themes and defaults

-- Use custom theme
beautiful.init("~/.config/awesome/theme.lua")
--local icon_path = "/home/corey/.config/awesome/icons/"

-- Set Wallpaper
for s = 1, screen.count() do
	gears.wallpaper.maximized(beautiful.wallpaper, s, true)
end

local terminal = "/home/corey/bin/st"

-- Set modkey to Win
local modkey = "Mod4"

-- Layouts for window tiling
awful.layout.layouts = {
	require("layout"),
}

-- }}}
-- {{{ Helpers:
local function partial(func, ...)
	local _args = {...}
	return function(...)
		local args = {...}
		for i, v in ipairs(_args) do
			table.insert(args, i, v)
		end
		return func(table.unpack(args))
	end
end
-- }}}
-- {{{ Status Bar
menubar.utils.terminal = terminal
menubar.show_categories = false
menubar.refresh()

local tags = {"1","2","3","4"}

awful.screen.connect_for_each_screen(function(s)
	local spacer = wibox.widget.textbox("  ")
	s.clock = wibox.widget.textclock(" %a %b %d, %I:%M %p")
	s.cpu = require("customWidgets.cpugraph")
	s.ram = require("customWidgets.ramgraph")
	s.wifi = require("customWidgets.wifi")
	s.battery = require("customWidgets.battery")

	-- each screens tag layout
	awful.tag(tags, s, awful.layout.layouts[1])
	-- tags
	s.taglist = awful.widget.taglist(
		s, -- screen
		awful.widget.taglist.filter.all --filter
	)
	-- setup the bar
	s.statusbar = awful.wibar{ position = "top", screen = s }
	s.statusbar:setup {
		layout = wibox.layout.align.horizontal,
		{ -- Left Widgets
			layout = wibox.layout.fixed.horizontal,
			s.clock,
		},
		{ -- Center
			layout = wibox.layout.fixed.horizontal,
			spacer,
		},
		{ -- Right Widgets
			layout = wibox.layout.fixed.horizontal,
			s.cpu, spacer,
			s.ram, spacer,
			s.wifi, spacer,
			s.battery or wibox.widget.textbox(" "),
			s.battery and spacer or wibox.widget.textbox(" "),
			s.taglist,
		},
	}
end)
-- }}}
-- {{{ Key Bindings

-- Aliases for convenience
local m 	= modkey
local crtl 	= "Control"
local shft 	= "Shift"
local alt 	= "Mod1"


local globalkeys = gears.table.join(
	awful.key(
		{m}, "s",
		hotkeys_popup.show_help,
		{ description="show help", group="awesome" }
	),
	awful.key(
		{m, shft}, "h",
		awful.tag.viewprev,
		{ description="view previous", group="tag" }
	),
	awful.key(
		{m,shft}, "l",
		awful.tag.viewnext,
		{ description="view next", group="tag" }
	),
	awful.key(
		{m}, "k",
		partial(awful.client.focus.byidx, -1),
		{ description="focus previous by index", group="client" }
	),
	awful.key(
		{m}, "j",
		partial(awful.client.focus.byidx, 1),
		{ description="focus next by index", group="client" }
	),

	-- Layouts
	awful.key(
		{m,shft}, "j",
		partial(awful.client.swap.byidx, 1),
		{ description="swap with next client by index", group="client" }
	),
	awful.key(
		{m,shft}, "k",
		partial(awful.client.swap.byidx, -1),
		{ description="swap with previous client by index", group="client" }
	),
	awful.key(
		{m,crtl}, "j",
		partial(awful.screen.focus_relative, 1)
		{ description="focus the next screen", group="screen" }
	),
	awful.key(
		{m,crtl}, "k",
		partial(awful.screen.focus_relative, -1)
		{ description="focus the previous screen", group="screen" }
	),
	awful.key(
		{m}, "Return",
		partial(awful.spawn, terminal),
		{ description="open a terminal", group="launcher" }
	),
	awful.key(
		{m,shft}, "Return",
		function()
			awful.spawn(terminal .. " -e sh", {
				floating = true,
				height = 400,
				width = 600,
				tag = mouse.screen.selected_tag,
				placement = awful.placement.under_mouse,
			})
		end,
		{ description="open a floating terminal", group="launcher" }
	),
	awful.key(
		{m,crtl}, "r",
		awesome.restart,
		{ description="restart awesome", group="awesome" }
	),
	awful.key(
		{m,shft}, "q",
		awesome.quit,
		{ description="quit awesome", group="awesome" }
	),
	awful.key(
		{m}, "r",
		menubar.show,
		{ description="run prompt", group="launcher" }
	),
	awful.key(
		{m,shft}, "r",
		function()
			menubar.refresh()
			menubar.show()
		end,
		{ description="reload and run prompt", group="launcher" }
	)
)

local clientkeys = gears.table.join(
	awful.key(
		{m}, "f",
		function(c)
			c.fullscreen = not c.fullscreen
			c:emit_signal("property::window")
		end,
		{ description="toggle fullscreen", group="client" }
	),
	awful.key(
		{m,shft}, "c",
		function(c) c:kill() end,
		{ description="close", group="client" }
	),
	awful.key(
		{m}, "space",
		function(c)
			awful.client.floating.toggle(c)
			c:emit_signal("property::window")
		end,
		{ description="toggle floating", group="client" }
	)
)

for i = 1, #tags do
	globalkeys = gears.table.join(
		globalkeys,
		awful.key(
			{alt}, "#" .. (i+9),
			function()
				local screen = awful.screen.focused()
				local tag    = screen.tags[i]
				if tag then
					tag:view_only()
				end
			end,
			{ description="view tag #" .. i, group="tag" }
		),
		awful.key(
			{m,shft}, "#" .. (i+9),
			function()
				if client.focus then
					local tag = client.focus.screen.tags[i]
					if tag then
						client.focus:move_to_tag(tag)
					end
				end
			end,
			{ description="move focused client to tag #"..i, group="tag" }
		),
		awful.key(
			{"Mod1",shft}, "#" .. (i+9),
			function()
				local screen = awful.screen.focused()
				local tag    = screen.tags[i]
				if tag then
					awful.tag.viewtoggle(tag)
				end
			end,
			{ description="toggle tag #" .. i, group="tag" }
		),

		awful.key(
			{m,crtl,shft}, "#" .. (i+9),
			function()
				if client.focus then
					local tag = client.focus.screen.tags[i]
					if tag then
						client.focus:toggle_tag(tag)
					end
				end
			end,
			{ description="toggle focused client on tag #" .. i, group="tag" }
		)

	)
end

root.keys(globalkeys)

-- Floating window resizing with the mouse
local clientbuttons = gears.table.join(
	awful.button({}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", {raise = c.floating})
	end),
	awful.button({m}, 1, function(c)
		c:emit_signal("request::activate", "mouse_click", {raise = c.floating})
		awful.mouse.client.move(c)
	end),
	awful.button({m}, 3, function(c)
		c:emit_signal("request::activate", "mouse_click", {raise = c.floating})
		awful.mouse.client.resize(c)
	end)
)

-- }}}
-- {{{ Rules
awful.mouse.snap.edge_enabled = false

awful.rules.rules = {
	{rule = {},
	 properties = { border_width	= beautiful.border_width,
	 		border_color	= beautiful.border_normal,
			focus		= awful.client.focus.filter,
			raise		= true,
			keys		= clientkeys,
			buttons		= clientbuttons,
			titlebars_enabled=false,
			screen		= awful.screen.preferred,
			honor_padding	= true,
			size_hints_honor= false,
			placement 	= awful.placement.no_offscreen }},

}
-- }}}
-- {{{ Signals
local default_border_width = beautiful.border_width
client.connect_signal("manage", function(c)
	if awesome.startup and
		not c.size_hints.user_position then
		awful.placement.no_offscreen(c)
	end

	--local buttons = gears.table.join(
	--awful.button({}, 1, function()
		--c:emit_signal("request::activate", "titlebar", {raise=true})
		--awful.mouse.client.move(c)
	--end),
	--awful.button({}, 3, function()
		--c:emit_signal("request::activate", "titlebar", {raise=true})
		--awful.mouse.client.resize(c)
	--end)
	--)
	c:emit_signal("property::window")
end)

client.connect_signal("unmanage", function(c)
	c:emit_signal("request::border")
end)

client.connect_signal("property::window", function(c)
	if c.floating then
		c:raise()
	else
		c:lower()
	end
	c:emit_signal("request::border")
end)

client.connect_signal("request::border", function(c)
	if c.floating then
		c.border_width = default_border_width
	else
		local client_amount = #c.screen.tiled_clients
		for _, cl in ipairs(c.screen.tiled_clients) do
			cl.border_width = client_amount == 1 and 0 or default_border_width
		end
	end
end)

-- Enable sloppy focus
client.connect_signal("mouse::enter", function(c)
	client.focus = c
end)

-- Change border when focused
client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)
-- }}}
