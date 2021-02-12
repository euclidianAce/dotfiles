
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

local function makeDefaultTable(): table
	return setmetatable({}, {
		__index = function(self: table, index: string): table
			rawset(self, index, {})
			return self[index] as table
		end
	})
end

local cmdf <const> = util.nvim.cmdf

local keymapper <const> = {
	_export = {
		mapping: {string:{string:function}} = makeDefaultTable() as {string:{string:function}},
		bufMapping: {number:{string:{string:function}}} = setmetatable({}, {
			__index = function(self: {number:{string:{string:function}}}, key: number): {string:{string:function}}
				cmdf("autocmd! BufUnload <buffer=%d> lua require('euclidian.lib.keymapper')._export.bufMapping[%d] = nil", key, key)
				rawset(self, key, makeDefaultTable())
				return rawget(self, key)
			end,
		}),
	},
}

local function keymapCallback(fn: function): function()
	local errored = false
	local err: string
	return function()
		if errored then
			a.nvim_err_writeln("Keymap previously errored: " .. err)
		else
			local ok, res = pcall(fn) as (boolean, string)
			if not ok then
				errored = true
				err = res
				a.nvim_err_writeln("Keymap errored: " .. err)
			end
		end
	end
end

local function sanitizeLhs(lhs: string): string
	return (lhs:gsub("<.->", function(_s: string): string
		local s = _s:sub(2, -2)
		if s == "leader" then
			return a.nvim_get_var("mapleader") as string
		elseif s:lower() == "esc" then
			return "_esc"
		end
		return _s
	end))
end

local function copyUserSettings(t: MapArgs): MapArgs
	return t and {
		nowait = t.nowait,
		silent = t.silent,
		script = t.script,
		expr = t.expr,
		unique = t.unique,
		noremap = t.noremap,
	} or {}
end

local function map(mode: string, lhs: string, rhs: string|function, userSettings: MapArgs)
	if rhs is string then
		a.nvim_set_keymap(mode, lhs, rhs, userSettings)
	elseif rhs is function then
		local correct_lhs <const> = sanitizeLhs(lhs)

		keymapper._export.mapping[mode][correct_lhs] = keymapCallback(rhs)
		local vimRhs <const> = string.format("<cmd>lua require('euclidian.lib.keymapper')._export.mapping[%q][%q]()<CR>", mode, lhs)
		a.nvim_set_keymap(mode, lhs, vimRhs, userSettings)
	end
end

local function bufMap(buf: number, mode: string, lhs: string, rhs: string|function, userSettings: MapArgs)
	if rhs is string then
		a.nvim_buf_set_keymap(buf, mode, lhs, rhs, userSettings)
	elseif rhs is function then
		local correct_lhs <const> = sanitizeLhs(lhs)

		keymapper._export.bufMapping[buf][mode][correct_lhs] = keymapCallback(rhs)
		local vimRhs <const> = string.format("<cmd>lua require('euclidian.lib.keymapper')._export.bufMapping[%d][%q][%q]()<CR>", buf, mode, lhs)
		a.nvim_buf_set_keymap(buf, mode, lhs, vimRhs, userSettings)
	end
end

function keymapper.map(mode: string, lhs: string, rhs: string|function, userSettings: MapArgs)
	map(mode, lhs, rhs, copyUserSettings(userSettings))
end

function keymapper.bufMap(buf: number, mode: string, lhs: string, rhs: string|function, userSettings: MapArgs)
	bufMap(buf, mode, lhs, rhs, copyUserSettings(userSettings))
end

function keymapper.noremap(mode: string, lhs: string, rhs: string|function, userSettings: MapArgs)
	local s = copyUserSettings(userSettings)
	s.noremap = true
	map(mode, lhs, rhs, s)
end

function keymapper.unmap(mode: string, lhs: string)
	pcall(a.nvim_del_keymap, mode, sanitizeLhs(lhs))
end

return keymapper

