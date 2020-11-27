
local record MapArgs
	nowait: boolean
	silent: boolean
	script: boolean
	expr: boolean
	unique: boolean
	noremap: boolean
end

local util <const> = require("euclidian.lib.util")
local a <const> = vim.api

local keymapper <const> = {
	_export = {
		mapping: {string:{string:function}} = setmetatable({}, {
			__index = function(self: table, index: string): table
				rawset(self, index, {})
				return self[index] as table
			end
		}),
	}
}

local function map(mode: string, lhs: string, rhs: string|function, user_settings: MapArgs)
	local user_settings = user_settings or {}
	if rhs is string then
		a.nvim_set_keymap(mode, lhs, rhs, user_settings)
	elseif rhs is function then
		-- make sure to sub in leader for the actual val cuz thats what vim will do with lhs
		local correct_lhs = lhs:gsub("<leader>", a.nvim_get_var("mapleader") as string)
		keymapper._export.mapping[mode][correct_lhs] = util.partial(pcall, rhs)
		a.nvim_set_keymap(
			mode,
			lhs,
			string.format(":lua require('euclidian.lib.keymapper')._export.mapping[%q][%q]()<CR>", mode, lhs),
			user_settings
		)
	end
end

function keymapper.map(mode: string, lhs: string, rhs: string|function, userSettings: MapArgs)
	map(mode, lhs, rhs, userSettings or {})
end

function keymapper.noremap(mode: string, lhs: string, rhs: string|function, userSettings: MapArgs)
	map(mode, lhs, rhs, vim.tbl_extend("keep", {noremap = true} as table, userSettings or {}) as MapArgs)
end

function keymapper.unmap(mode: string, lhs: string)
	local correct_lhs = lhs:gsub("<leader>", a.nvim_get_var("mapleader") as string)
	pcall(a.nvim_del_keymap, mode, correct_lhs)
end

return keymapper
