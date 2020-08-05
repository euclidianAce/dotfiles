
local a = vim.api

-- {{{ helpers
local export = {
	mapping: {string:function} = {},
}

-- local function partial(f: function, a: any): function(...: any): any...
-- 	return function(...: any): any...
-- 		return f(a, ...)
-- 	end
-- end

local function trim(s: string): string
	return (s:gsub("%s*(.*)%s*", "%1"))
end

-- Keymaps with lua functions
local settings = {noremap = true, silent = true}
local function map(mode: string, lhs: string, rhs: string|function)
	if rhs is string then
		a.nvim_set_keymap(mode, lhs, rhs, settings)
	elseif rhs is function then
		-- make sure to sub in leader for the actual val cuz thats what vim will do with rhs
		export.mapping[lhs:gsub("<leader>", a.nvim_get_var("mapleader") as string)] = rhs
		a.nvim_set_keymap(
			mode,
			lhs,
			string.format(":lua require('config').mapping[%q]()<CR>", lhs),
			settings
		)
	end
end

local function unmap(mode: string, lhs: string)
	pcall(a.nvim_del_keymap, mode, lhs)
end

local cmd = a.nvim_command
-- }}}
-- {{{ LSP
local lsp = require("nvim_lsp")
local lspSettings = {
	sumneko_lua = { settings = { Lua = {
		runtime = { version = "Lua 5.3" },
		diagnostics = { globals = {
			-- Vim api
			"vim",

			-- Tupfile.lua
			"tup",

			-- Busted
			"it",
			"describe",
			"setup",
			"teardown",
			"pending",
			"finally",

			-- Computercraft
			"turtle",
			"fs",
			"shell",
		} }
	} } },
	clangd = {},
}

for server, settings in pairs(lspSettings) do
	lsp[server].setup(settings)
end
-- }}}
-- {{{ Statusline Config
local stl = require("statusline")

stl.mode("ic", "Insert-C", "DraculaGreenBold")
stl.mode("ix", "Insert-X", "DraculaGreenBold")
stl.mode("R", "Replace", "DraculaRed")
stl.mode("t", "Terminal", "DraculaOrange")

stl.add({"LeadingSpace", "Spaces", "Active", "Inactive"}, {}, " ", "Comment")
stl.add({"ModeText", "Active"}, {"Inactive"}, function(): string
	return "[" .. stl.getModeText() .. "]"
end, "StatuslineModeText")
stl.add({"BufferNumber", "Active", "Inactive"}, {"Debugging"}, "[buf: %n]", "Comment")
stl.add({"FileName", "Active", "Inactive"}, {"Debugging"}, "[%.30f]", "Identifier")
stl.add({"GitBranch", "Active", "Inactive"}, {"Debugging"}, "%{FugitiveStatusline()}", "Special")
stl.add({"EditInfo", "Active", "Inactive"}, {"Debugging"}, "%y%r%h%w%m ", "Comment")
stl.add({"SyntaxViewer", "Debugging"}, {"Inactive"}, function(): string
	local cursor = a.nvim_win_get_cursor(0)
	return "[Syntax: " .. vim.fn.synIDattr(vim.fn.synID(cursor[1], cursor[2]+1, 0), "name") as string .. "]"
end, "DraculaOrangeBold")
stl.add({"IndentViewer", "Debugging"}, {"Inactive"}, function(): string
	local indentexpr: string
	do
		local ok: boolean
		ok, indentexpr = pcall(a.nvim_buf_get_option, 0, "indentexpr") as (boolean, string)
		if not ok or not indentexpr then
			return ""
		end
	end
	local shiftwidth: number = a.nvim_buf_get_option(0, "shiftwidth") as number
	if not shiftwidth then
		shiftwidth = 1
	end
	local cursor = a.nvim_win_get_cursor(0)
	local indent: number
	do
		local ok: boolean
		ok, indent = pcall(vim.fn[indentexpr:gsub("%(.*$", "")], tostring(cursor[1])) as (boolean, number)
		if not ok or not indent then
			return ""
		end
	end
	return ("[Indent: %d]"):format(indent / shiftwidth)
end, "DraculaGreenBold")
stl.add({"ActiveSeparator", "Active"}, {"Inactive"}, "%=", "User1")
stl.add({"InactiveSeparator", "Inactive"}, {"Active"}, "%=", "User2")
stl.add({"Active"}, {"Inactive"}, function(): string
	local sw = a.nvim_buf_get_option(0, "shiftwidth") as number
	local ts = a.nvim_buf_get_option(0, "tabstop") as number
	return (" [sw:%d ts:%d]"):format(sw, ts)
end, "Identifier")
stl.add({"LineNumber", "NavInfo", "Active", "Inactive"}, {}, " %l/%L:%c ", "Comment")
stl.add({"FilePercent", "NavInfo", "Active", "Inactive"}, {"Debugging"}, "%3p%%", "Comment")
stl.add({"TrailingSpace", "Spaces", "Active", "Inactive"}, {}, " ", "Comment")

cmd("hi! User2 guibg=#1F1F1F")
cmd("hi! link User1 Visual")

map("n", "<F12>", function() stl.toggleTag("Debugging") end)
-- }}}
-- {{{ Other Stuffs

-- Put the current visual selection in a fold
local function foldVisualSelection(): number, number
	local start = a.nvim_buf_get_mark(0, "<")[1]-1
	local finish = a.nvim_buf_get_mark(0, ">")[1]+1
	local commentstring = a.nvim_buf_get_option(0, "commentstring") as string
	a.nvim_buf_set_lines(0, start, start, true, {string.format(commentstring, " {{{")})
	a.nvim_buf_set_lines(0, finish, finish, true, {string.format(commentstring, " }}}")})
	return start, finish
end
map("v", "<leader>f", foldVisualSelection)
-- same but go into insert mode to give it a label
map("v", "<leader>F", function()
	local start = foldVisualSelection()
	a.nvim_win_set_cursor(0, {start+1, 1})
	a.nvim_input("A ")
end)
map("v", "<leader>s", ":sort<CR>")

local function termFunc()
	local cmd: string = vim.fn.input("Command to execute in terminal: ") as string
	if #trim(cmd) == 0 then
		return
	end
	a.nvim_command("sp +term")
	local termWin: number = a.nvim_win_get_number(0)
	local ok, res: boolean, number = pcall(a.nvim_buf_get_var, 0, "terminal_job_id") as (boolean, number)
	if not ok then
		print("unable to get terminal job id\n")
		return
	end
	unmap("n", "<leader>t")
	map("n", "<leader>t", function()
		pcall(vim.fn.chansend, res, cmd .. "\n")
	end)
	map("n", "<leader>T", function()
		pcall(a.nvim_win_close, termWin, true)
		unmap("n", "<leader>T")
		map("n", "<leader>t", termFunc)
	end)
	print("Press <leader>t to execute ", cmd, "\n", "Press <leader>T to close the terminal\n")
end

map("n", "<leader>t", termFunc)
-- }}}

return export
