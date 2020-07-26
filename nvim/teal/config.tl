
local a = vim.api

-- {{{ helpers
local export = {
	mapping: {string:function} = {},
}

-- Keymaps with lua functions
local function map(mode: string, lhs: string, rhs: string|function)
	local settings = {noremap = true, silent = true}
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

stl.mode("n", "Normal", "DraculaPurple")
stl.mode("i", "Insert", "DraculaGreen")
stl.mode("ic", "Insert-C", "DraculaGreenBold")
stl.mode("ix", "Insert-X", "DraculaGreenBold")
stl.mode("R", "Replace", "DraculaRed")
stl.mode("v", "Visual", "DraculaYellow")
stl.mode("V", "Visual Line", "DraculaYellow")
stl.mode("", "Visual Block", "DraculaYellow")
stl.mode("c", "Command", "DraculaPink")
stl.mode("s", "Select", "DraculaYellow")
stl.mode("S", "Select Line", "DraculaYellow")
stl.mode("", "Select Block", "DraculaYellow")
stl.mode("t", "Terminal", "DraculaOrange")
stl.mode("!", "Shell...", "Comment")

stl.add({"LeadingSpace", "Spaces", "Active", "Inactive"}, {}, " ", "Comment")
stl.add({"ModeText", "Active"}, {"Inactive"}, [=[[%{luaeval("require'statusline'.getModeText()")}]]=], "User3")
stl.add({"BufferNumber", "Active", "Inactive"}, {"Debugging"}, "[buf: %n]", "Comment")
stl.add({"FileName", "Active", "Inactive"}, {"Debugging"}, "[%.30f]", "Identifier")
stl.add({"EditInfo", "Active", "Inactive"}, {"Debugging"}, "%y%r%h%w%m ", "Comment")
-- stl.add({"SyntaxViewer", "Debugging"}, {"Inactive"}, [[ [%{synIDattr(synID(line("."), col("."), 0), "name")}]  ]], "DraculaPurpleBold")
stl.add({"SyntaxViewer", "Debugging"}, {"Inactive"}, function(): string
	local cursor = a.nvim_win_get_cursor(0)
	return "[" .. vim.fn.synIDattr(vim.fn.synID(cursor[1], cursor[2]+1, 0), "name") as string .. "]"
end, "DraculaPurpleBold")
-- stl.add({"IndentViewer", "Debugging"}, {"Inactive"}, [[ [Current Teal Indent: %{GetTealIndent(line(".")) / &shiftwidth}]  ]], "DraculaPurpleBold")
stl.add({"IndentViewer", "Debugging"}, {"Inactive"}, function(): string
	local indentexpr: string = a.nvim_buf_get_option(0, "indentexpr") as string
	if not indentexpr then
		return ""
	end
	local shiftwidth: number = a.nvim_buf_get_option(0, "shiftwidth") as number
	if not shiftwidth then
		shiftwidth = 1
	end
	local cursor = a.nvim_win_get_cursor(0)
	local indent = vim.fn[indentexpr:gsub("%(.*$", "")](tostring(cursor[1])) as number
	return ([=[[Indent: %d]]=]):format(indent / shiftwidth)
end, "DraculaPurpleBold")
stl.add({"ActiveSeparator", "Active"}, {"Inactive"}, "%=", "User1")
stl.add({"InactiveSeparator", "Inactive"}, {"Active"}, "%=", "User2")
stl.add({"LineNumber", "NavInfo", "Active", "Inactive"}, {}, " %l/%L:%c ", "Comment")
stl.add({"FilePercent", "NavInfo", "Active", "Inactive"}, {"Debugging"}, "%3p%%", "Comment")
stl.add({"TrailingSpace", "Spaces", "Active", "Inactive"}, {}, " ", "Comment")

cmd("hi! User2 guibg=#1F1F1F")
cmd("hi! link User1 Visual")

map("n", "<F12>", function() stl.toggleTag('Debugging') end)
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
-- }}}

return export
