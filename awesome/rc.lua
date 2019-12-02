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
	awesome.connect_signal("debug::error",
		function(err)
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

-- Set Wallpaper
for s = 1, screen.count() do
	gears.wallpaper.maximized(beautiful.wallpaper, s, true)
end

-- Set default terminal and editor
terminal   = "urxvt"
editor     = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Set modkey to Win
modkey = "Mod4"

-- Layouts for window tiling
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
}

-- }}}

-- {{{ Menubar

menubar.utils.terminal = terminal

-- create a wibox for each screen
local taglist_buttons = gears.table.join(
	awful.button({}, 1, function(t) t:view_only() end),
	awful.button({modkey}, 1, function(t)
				  	if client.focus then
						client.focus:move_to_tag(t)
					end
				  end),
	awful.button({}, 3, awful.tag.viewtoggle),
	awful.button({modkey}, 3, function(t)
					if client.focus then
						client.focus:toggle_tag(t)
					end
				  end),
	awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
	awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
	awful.button({}, 1, function(c)
		if c == client.focus then
			c.minimized = true
		else
			c:emit_signal(
				"request::activate",
				"tasklist",
				{raise = true}
			)
		end
	end),

	awful.button({}, 3, function()
		awful.menu.client_list({ theme = {width = 250}})
	end),
	awful.button({}, 4, function()
		awful.client.focus.byidx(1)
	end),
	awful.button({}, 5, function()
		awful.client.focus.byidx(-1)
	end)
)

local tags = {"1","2","3","4","5","6","7","8","9"}

awful.screen.connect_for_each_screen(function(s)
	-- each screens tag layout
	awful.tag(tags, s, awful.layout.layouts[1])

	-- each screens prompt box
	s.mypromptbox = awful.widget.prompt()

	-- tags	
	s.mytaglist = awful.widget.taglist(
		s, -- screen
		awful.widget.taglist.filter.all, --filter
		taglist_buttons --buttons
	)

	-- setup the bar
	s.mywibox = awful.wibar{ position = "top", screen = s }
	s.mywibox:setup {
		layout = wibox.layout.align.horizontal,
		{ -- Left Widgets
			layout = wibox.layout.fixed.horizontal,
			wibox.widget.textclock()
		},
		{ -- Center
			layout = wibox.layout.fixed.horizontal,
			s.mypromptbox,
			mylauncher,
			wibox.widget.textbox(""),
		},
		{ -- Right Widgets
			layout = wibox.layout.fixed.horizontal,
			s.mytaglist,
		},
	}
end)
-- }}}

-- {{{ Key Bindings 
-- function for adjusting gaps

local function change_gaps(amount)
	beautiful.useless_gap = math.max(beautiful.useless_gap + amount, 0)
	-- show notification of new gap size
	naughty.notify{
		position = "top_middle",
		text = "Gap Size: "..beautiful.useless_gap,
		timeout = 1,
	}

	-- update clients
	for _, c in ipairs(client.get()) do
		c:emit_signal("property::window")
		c:emit_signal("list")
	end
end

local m, crtl, shft = modkey, "Control", "Shift" -- Aliases for convenience 
globalkeys = gears.table.join(
--	awful.key(KEYS			FUNCTION			DESCRIPTION)
	awful.key({m},"s", 		hotkeys_popup.show_help, 	{description="show help", 
									 group="awesome"					}),
	
	awful.key({m,shft},"h",		awful.tag.viewprev, 		{description="view previous", 
									 group="tag"						}),
	
	awful.key({m,shft},"l", 	awful.tag.viewnext, 		{description="view next", 
									 group="tag"						}),
	
	awful.key({m},"k", 		function() 
						awful.client.focus.byidx(-1) 
					end, 				{description="focus previous by index", 
									 group="client"						}),
	
	awful.key({m},"j", 		function() 
						awful.client.focus.byidx(1) 
					end, 				{description="focus next by index", 
									 group="client"						}),
	-- Layouts
	awful.key({m,shft},"j",		function() 
						awful.client.swap.byidx(1)
					end,				{description	="swap with next client by index", 
									 group		="client"				}),
	awful.key({m,shft},"k",		function()
						awful.client.swap.byidx(-1)
					end,				{description	="swap with previous client by index", 
									 group		="client"				}),
	awful.key({m,crtl},"j", 	function()
						awful.screen.focus_relative(1)
					end,				{description	="focus the next screen",
									 group		="screen"				}),
	awful.key({m,crtl},"k", 	function()
						awful.screen.focus_relative(-1)
					end,				{description	="focus the previous screen",
									 group		="screen"				}),
	awful.key({m},"Return",		function()
						awful.spawn(terminal)
					end,				{description	="open a terminal",
									 group		="launcher"				}),
	awful.key({m},"space",		function()
						awful.layout.inc(1)
					end,				{description	="Toggle tiling method",
									 group		="client"				}),

	awful.key({m,crtl},"r", 	awesome.restart,		{description	="restart awesome",
									 group		="awesome"				}),

	awful.key({m,shft},"q", 	awesome.quit,			{description	="quit awesome",
									 group		="awesome"				}),

	awful.key({m},"l", 		function()
						awful.tag.incmwfact(0.05)
					end,				{description	="increase width",
									 group		="layout"				}),

	awful.key({m},"h", 		function()
						awful.tag.incmwfact(-0.05)
					end,				{description	="decrease width",
									 group		="layout"				}),

	awful.key({m},"r", 		function()
						awful.screen.focused().mypromptbox:run()
					end,				{description	="run prompt",
									 group		="launcher"				}),
	awful.key({m},"g",		function() 
						change_gaps(1)
					end,				{description	="increase gaps",
									 group		="layout"				}),

	awful.key({m,shft},"g",		function() 
						change_gaps(-1)
					end,				{description	="decrease gaps",
									 group		="layout"				})
)

clientkeys = gears.table.join(
	
	awful.key({m}, "f", 		function(c)
						c.fullscreen = not c.fullscreen
						c:raise()
					end,				{description	="toggle fullscreen",
									 group		="client"}),
	awful.key({m,shft},"c",		function(c) c:kill() end,	{description	="close",
									 group		="client"}),

	awful.key({m,crtl},"space", 	awful.client.floating.toggle,	{description	="toggle floating",
									 group		="client"}),
	
	awful.key({m,crtl},"Return",	function(c) 
						c:swap(awful.client.getmaster()) 
					end, 				{description	="swap with master",
									 group		="client"})
)


for i = 1, #tags do
	globalkeys = gears.table.join(
		globalkeys,
		awful.key({"Mod1"}, "#" .. i+9,
			function()
				local screen = awful.screen.focused()
				local tag    = screen.tags[i]
				if tag then
					tag:view_only()
				end
			end,
			{description = "view tag #"..i,
			 group	     = "tag"}
		),

		awful.key({m,shft}, "#" .. i+9,
			function()
				if client.focus then
					local tag = client.focus.screen.tags[i]
					if tag then
						client.focus:move_to_tag(tag)
					end
				end
			end,
			{description = "move focused client to tag #"..i,
			 group	     = "tag"}
		),

		awful.key({"Mod1",shft}, "#" .. i+9,
			function()
				local screen = awful.screen.focused()
				local tag    = screen.tags[i]
				if tag then
					awful.tag.viewtoggle(tag)
				end
			end,
			{description = "toggle tag #" .. i,
			 group	     = "tag"}
		),

		awful.key({m,crtl,shft}, "#" .. i+9,
			function()
				if client.focus then
					local tag = client.focus.screen.tags[i]
					if tag then
						client.focus:toggle_tag(tag)
					end
				end
			end,
			{description = "toggle focused client on tag #" .. i,
			 group	     = "tag"}
		)

	)
end

root.keys(globalkeys)
-- }}}

-- {{{ Rules

awful.rules.rules = {
	{rule = {},
	 properties = { border_width	= beautiful.border_width,
	 		border_color	= beautiful.border_normal,
			focus		= awful.client.focus.filter,
			raise		= true,
			keys		= clientkeys,
			buttons		= clientbuttons,
			screen		= awful.screen.preferred,
			honor_padding	= true,
			size_hints_honor= false,
			placement 	= awful.placement.no_overlap + awful.placement.no_offscreen }}
}
-- }}}

-- {{{ Signals

client.connect_signal("manage", 
	function(c)
		if awesome.startup and
		not c.size_hints.user_position then
			awful.placement.no_offscreen(c)
		end
	end
)

client.connect_signal("property::window",
	function(c)
		if beautiful.useless_gap > 0 then
			c.shape = function(cr, width, height)
				gears.shape.rounded_rect(cr, width, height, 10)
			end
		else
			c.shape = gears.shape.rect
		end
	end
)


-- Enable sloppy focus
client.connect_signal("mouse::enter",
	function(c)
		if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier and
		awful.client.focus.filter(c) then
			client.focus = c
		end
	end
)


-- Change border when focused
client.connect_signal("focus", 
	function(c)
		c.border_color = beautiful.border_focus
	end
)
client.connect_signal("unfocus",
	function(c)
		c.border_color = beautiful.border_normal
	end
)
-- }}}

