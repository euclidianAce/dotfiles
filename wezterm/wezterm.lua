local wezterm = require "wezterm"

local config = wezterm.config_builder and wezterm.config_builder() or {}

-- config.font = wezterm.font "CozetteVector"
-- config.font_size = 8

-- config.font = wezterm.font "UbuntuMono"
-- config.font_size = 10

config.font = wezterm.font "Terminus (TTF)"
config.font_size = 9

-- config.font = wezterm.font "Atkinson Hyperlegible Mono"

-- Works around a rendering bug
config.front_end = "WebGpu"

config.colors = {
	foreground = "#d8cee4",
	background = "#181520",

	ansi = {
		"#464252",
		"#d16161",
		"#53b67e",
		"#d5c876",
		"#799ae0",
		"#c24472",
		"#429da0",
		"#817998",
	},
	brights = {
		"#817998",
		"#e69090",
		"#7bce8f",
		"#f0e7ac",
		"#aac3fd",
		"#ef6194",
		"#70c3c6",
		"#efefef",
	}
}

config.hide_tab_bar_if_only_one_tab = true

return config
