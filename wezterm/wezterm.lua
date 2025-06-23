local wezterm = require "wezterm"

local config = wezterm.config_builder and wezterm.config_builder() or {}

do
	config.colors = {}
	local ok, color_entries = pcall(require, "color")
	if ok then
		for k, v in pairs(color_entries) do
			config.colors[k] = v
		end
	end
end

-- config.font = wezterm.font "CozetteVector"
-- config.font_size = 8

-- config.font = wezterm.font "UbuntuMono"
-- config.font_size = 12

-- config.font = wezterm.font "Terminus (TTF)"
-- config.font_size = 9

config.font = wezterm.font "Atkinson Hyperlegible Mono"
config.font_size = 12

-- Works around a rendering bug
config.front_end = "WebGpu"

config.hide_tab_bar_if_only_one_tab = true

return config
