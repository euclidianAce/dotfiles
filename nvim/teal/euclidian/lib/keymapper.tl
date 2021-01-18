
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
	user_settings = user_settings or {}
	if rhs is string then
		a.nvim_set_keymap(mode, lhs, rhs, user_settings)
	elseif rhs is function then
		-- make sure to sub in leader for the actual val cuz thats what vim will do with lhs
		-- TODO: this doesn't sometimes for <C- and <M- mappings due to the raw chars being set
		-- at one point I thought there was a function to escape/translate these but i cant find it
		local correct_lhs <const> = lhs:gsub("<leader>", a.nvim_get_var("mapleader") as string)
		keymapper._export.mapping[mode][correct_lhs] = util.partial(pcall, rhs)
		local vimRhs <const> = string.format("<cmd>lua require('euclidian.lib.keymapper')._export.mapping[%q][%q]()<CR>", mode, lhs)
		a.nvim_set_keymap(
			mode,
			lhs,
			vimRhs,
			user_settings
		)
	end
end

local function copyUserSettings(t: MapArgs): MapArgs
	return {
		nowait = t.nowait,
		silent = t.silent,
		script = t.script,
		expr = t.expr,
		unique = t.unique,
		noremap = t.noremap,
	}
end

function keymapper.map(mode: string, lhs: string, rhs: string|function, userSettings: MapArgs)
	map(mode, lhs, rhs, copyUserSettings(userSettings))
end

function keymapper.noremap(mode: string, lhs: string, rhs: string|function, userSettings: MapArgs)
	local s = copyUserSettings(userSettings)
	s.noremap = true
	map(mode, lhs, rhs, s)
end

function keymapper.unmap(mode: string, lhs: string)
	local correct_lhs = lhs:gsub("<leader>", a.nvim_get_var("mapleader") as string)
	pcall(a.nvim_del_keymap, mode, correct_lhs)
end

return keymapper
