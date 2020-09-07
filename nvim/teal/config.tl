
package.loaded["config"] = nil

local a = vim.api
local cmd = a.nvim_command

-- {{{ helpers
local export = {
	mapping: {string:{string:function}} = setmetatable({}, {
		__index = function(self: table, index: string): table
			rawset(self, index, {})
			return self[index] as table
		end
	}),
	autocommands: {string:function} = {},
}
-- {{{ Random stuffs
local function cmdf(command: string, ...: any)
	cmd(command:format(...))
end

local function partial<T, K>(f: function(...: T): K..., a: T): function(...: T): K...
	return function(...: T): K...
		return f(a, ...)
	end
end

local function trim(s: string): string
	return (s:gsub("%s*(.*)%s*", "%1"))
end

local function fstsnd<T>(arr: {{T}}): function(): (T, T)
	local i = 0
	return function(): T, T
		i = i + 1
		if not arr[i] then
			return
		end
		return arr[i][1], arr[i][2]
	end
end
-- }}}
-- {{{ Keymaps with lua functions
local settings: {string:any} = {noremap = true, silent = true}
local function map(mode: string, lhs: string, rhs: string|function, user_settings: {string:any})
	local user_settings = user_settings or settings
	if rhs is string then
		a.nvim_set_keymap(mode, lhs, rhs, user_settings)
	elseif rhs is function then
		-- make sure to sub in leader for the actual val cuz thats what vim will do with lhs
		local correct_lhs = lhs:gsub("<leader>", a.nvim_get_var("mapleader") as string) 
		export.mapping[mode][correct_lhs] = partial(pcall, rhs)
		a.nvim_set_keymap(
			mode,
			lhs,
			string.format(":lua require('config').mapping[%q][%q]()<CR>", mode, lhs),
			user_settings
		)
	end
end

local function unmap(mode: string, lhs: string)
	local correct_lhs = lhs:gsub("<leader>", a.nvim_get_var("mapleader") as string) 
	pcall(a.nvim_del_keymap, mode, correct_lhs)
end
-- }}}
-- {{{ Autocmd with lua functions
-- local function autocmd(buf: number, group: string, patt: string, func: function)
-- 	local entry = group .. patt
-- 	export.autocommands[entry] = func
-- 	cmdf("autocmd <buffer=%d> %s %s :lua require('config').autocommands[%q]()<CR>", buf, group, patt, entry)
-- end
-- }}}
-- }}}
-- {{{ LSP
local lsp = require("nvim_lsp")
local lspSettings = {
-- {{{ sumneko lua
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

			-- awesomewm
			"awesome",
			"screen",
			"mouse",
			"client",
			"root",
		} }
	} } },
-- }}}
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
stl.add({"GitBranch", "Active", "Inactive"}, {"Debugging"}, function(): string
	-- [Git(branch)]
	local branch = (vim.fn.FugitiveStatusline() as string):sub(6, -3)
	if branch == "" then
		return ""
	end
	return "[* " .. branch .. "]"
end, "DraculaGreen")
stl.add({"EditInfo", "Active", "Inactive"}, {"Debugging"}, "%y%r%h%w%m ", "Comment")
stl.add({"SyntaxViewer", "Debugging"}, {"Inactive"}, function(): string
	local cursor = a.nvim_win_get_cursor(0) as {number}
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
	local cursor = a.nvim_win_get_cursor(0) as {number}
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
stl.add({"Shiftwidth", "Tabstop", "Active"}, {"Inactive"}, function(): string
	local sw = a.nvim_buf_get_option(0, "shiftwidth") as number
	local ts = a.nvim_buf_get_option(0, "tabstop") as number
	return (" [sw:%d ts:%d]"):format(sw, ts)
end, "Identifier")
stl.add({"LineNumber", "NavInfo", "Active", "Inactive"}, {}, " %l/%L:%c ", "Comment")
stl.add({"FilePercent", "NavInfo", "Active", "Inactive"}, {"Debugging"}, "%3p%%", "Comment")
stl.add({"TrailingSpace", "Spaces", "Active", "Inactive"}, {}, " ", "Comment")

cmd("hi! User1 guibg=#6F6F6F")
cmd("hi! User2 guibg=#1F1F1F")

map("n", "<F12>", function() stl.toggleTag("Debugging") end)
-- }}}
-- {{{ Other Stuffs
-- {{{ vim-commentary imitation
local commenter = require("commenter")
map("n", "<leader>c", function()
	local cursorPos: {number} = a.nvim_win_get_cursor(0)
	commenter.commentLine(0, cursorPos[1])
end)
map("v", "<leader>c", function()
	local start = (a.nvim_buf_get_mark(0, "<") as {number})[1]
	local finish = (a.nvim_buf_get_mark(0, ">") as {number})[1]
	for i = start, finish do
		commenter.commentLine(0, i)
	end
end)
-- }}}
-- {{{ Window movement/resizing
for mvkey, szkey in fstsnd{
	{"h", "<"},
	{"j", "+"},
	{"k", "-"},
	{"l", ">"}} do
	unmap("n", "<C-W>" .. mvkey)
	map("n", "<C-" .. mvkey .. ">", ":wincmd " .. mvkey .. "<CR>")
	map("n", "<M-" .. mvkey .. ">", "<C-w>3" .. szkey)
	map("n", "<C-w>" .. mvkey, ":echoerr 'stop that'<CR>")
end
-- }}}
-- {{{ Fold visual selection
local function foldVisualSelection(label: string): number, number
	-- I know that zf exists but it doesn't work the way I want it to
	local start = (a.nvim_buf_get_mark(0, "<") as {number})[1]-1
	local finish = (a.nvim_buf_get_mark(0, ">") as {number})[1]+1
	local commentstring = a.nvim_buf_get_option(0, "commentstring") as string
	local lb, rb = "{", "}"
	a.nvim_buf_set_lines(0, start, start, true, {string.format(commentstring, " " .. lb:rep(3) .. (label and (" " .. label) or "") .. " ")})
	a.nvim_buf_set_lines(0, finish, finish, true, {string.format(commentstring, " " .. rb:rep(3))})
	return start, finish
end
map("v", "<leader>f", foldVisualSelection)
map("v", "<leader>F", function()
	local label: string = vim.fn.input("Fold label: ") as string
	local _, finish = foldVisualSelection(label)
	a.nvim_win_set_cursor(0, {finish+1, 1})
end)
-- }}}
-- {{{ Spawn terminal with command binding
local function termFunc()
	local termCmd: string = vim.fn.input("Command to execute in terminal: ") as string
	if #trim(termCmd) == 0 then
		return
	end
	cmd("sp +term")
	local termWin = a.nvim_get_current_win() as number
	local ok, job: boolean, number = pcall(a.nvim_buf_get_var, 0, "terminal_job_id") as (boolean, number)
	if not ok then
		print("Unable to get terminal job id\n")
		return
	end
	unmap("n", "<leader>t")
	unmap("n", "<leader>T")
	map("n", "<leader>t", function()
		local ok = pcall(vim.fn.chansend, job, termCmd .. "\n")
		if not ok then
			print("[<leader>t] Unable to send command to terminal, (" .. termCmd .. ")")
		end
	end)
	map("n", "<leader>T", function()
		pcall(a.nvim_win_close, termWin, true)
		unmap("n", "<leader>T")
		map("n", "<leader>t", termFunc)
	end)
	print(", [<leader>t execute '" .. termCmd ..  "'] [<leader>T close]")
end

map("n", "<leader>t", termFunc)
-- }}}
-- }}}

return export
