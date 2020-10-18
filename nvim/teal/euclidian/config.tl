
package.loaded["euclidian.config"] = nil

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
	stuff: {string:function} = {},
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
	return (s:gsub("^%s*(.*)%s*$", "%1"))
end

global unpack: function<T>({T}): T...
-- TODO: fix
-- https://github.com/teal-language/tl/issues/237
local function unpacker<T>(arr: {{T}}): function(): T, T, T, T...
	local i = 0
	return function(): T, T, T, T...
		i = i + 1
		if not arr[i] then return end
		return unpack(arr[i])
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
			string.format(":lua require('euclidian.config').mapping[%q][%q]()<CR>", mode, lhs),
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
-- 	cmdf("autocmd <buffer=%d> %s %s :lua require('euclidian.config').autocommands[%q]()<CR>", buf, group, patt, entry)
-- end
-- }}}
-- }}}
-- {{{ LSP
local lsp = require("nvim_lsp")
local lspSettings = {
-- {{{ sumneko lua
	sumneko_lua = { settings = { Lua = {
		runtime = { version = "Lua 5.3" },
		diagnostics = {
			globals = {
				-- Vim api
				"vim",

				-- Tupfile.lua
				"tup",

				-- Busted
				"it", "describe", "setup", "teardown", "pending", "finally",

				-- Computercraft
				"turtle", "fs", "shell",

				-- awesomewm
				"awesome", "screen", "mouse", "client", "root",
			},
			disable = {
				"empty-block",
				"undefined-global",
				"unused-function",
			},
		},
	} } },
-- }}}
	clangd = {},
}

for server, settings in pairs(lspSettings) do
	lsp[server].setup(settings)
end
-- }}}
-- {{{ Statusline Config
local dracula = {
	background = "#282a36",
	currentLine = "#44475a",
	foreground = "#f8f8f2",
	comment = "#6272a4",
	cyan = "#8be9fd",
	green = "#50fa7b",
	orange = "#ffb86c",
	pink = "#ff79c6",
	purple = "#bd93f9",
	red = "#ff5555",
	yellow = "#f1fa8c",
}
local stl = require("euclidian.statusline")
local stlHiGroup <const> = "mySTL"
local function addHiGroup(name: string, fg: string, bg: string)
	cmd(
		"hi! def " .. name
			.. " guifg=" .. fg
			.. " guibg=" .. bg
	)
end
for mode, text, fg, bg in unpacker{
	{"n", "Normal", dracula.background, dracula.cyan},
	{"i", "Insert", dracula.background, dracula.green},
	{"ic", "Insert-Completion", dracula.background, dracula.green},
	{"c", "Command", dracula.background, dracula.pink},
	{"R", "Replace", dracula.background, dracula.red},
	{"t", "Terminal", dracula.background, dracula.orange},
	{"v", "Visual", dracula.background, dracula.yellow},
	{"V", "Visual Line", dracula.background, dracula.yellow},
	{"", "Visual Block", dracula.background, dracula.yellow},
} do
	addHiGroup(stlHiGroup .. mode, fg, bg)
	stl.mode(mode, text, stlHiGroup .. mode)
end

for hiGroupName, fg, bg in unpacker{
	{"CommentInverted", dracula.background, dracula.comment},
	{"TextInverted", dracula.background, dracula.foreground},
	{"GreenInverted", dracula.background, dracula.green},
	{"BrightGrayBg", dracula.background, "#6F6F6F"},
	{"DarkGrayBg", dracula.background, "#1F1F1F"},
	{"GitGreen", dracula.background, "#34d058"},
} do
	addHiGroup(hiGroupName, fg, bg)
end

local winOption <const> = a.nvim_win_get_option
stl.add({"LeadingSpace", "Spaces", "Active", "Inactive"}, {}, function(winId: number): string
	return (" "):rep(winOption(winId, "numberwidth") as number + winOption(winId, "foldcolumn") as number + 1)
end, "CommentInverted")
stl.add({"BufferNumber", "Active", "Inactive"}, {}, "%n ", "CommentInverted")
stl.add({"ModeText", "Active"}, {"Inactive"}, function(): string
	return " " .. stl.getModeText() .. " "
end, "StatuslineModeText")
stl.add({"GitBranch", "Active", "Inactive"}, {"Debugging"}, function(): string
	-- [Git(branch)]
	local branch = (vim.fn.FugitiveStatusline() as string):sub(6, -3)
	if branch == "" then
		return ""
	end
	return "  * " .. branch .. " "
end, "GitGreen")
local maxFileNameLen <const> = 20
stl.add({"FileName", "Active", "Inactive"}, {"Debugging"},
function(winId: number): string
	local ok, buf = pcall(a.nvim_win_get_buf, winId)
	if ok and buf then
		local fname = a.nvim_buf_get_name(buf)
		if fname:match("/bin/bash$") then
			return ""
		end
		if #fname > maxFileNameLen then
			return "  <" .. fname:sub(-maxFileNameLen, -1)
		end
		return "  " .. fname
	end
	return " ??? "
end, "BrightGrayBg")
stl.add({"EditInfo", "Inactive"}, {"Debugging", "Active"}, "%m ", "BrightGrayBg")
stl.add({"EditInfo", "Active"}, {"Debugging", "Inactive"}, "%m", "BrightGrayBg")
stl.add({"EditInfo", "Active"}, {"Debugging", "Inactive"}, "%r%h%w", "BrightGrayBg")
-- {{{ Syntax debugging 
-- stl.add({"SyntaxViewer", "Treesitter", "Debugging"}, {"Inactive"}, function(): string
	-- return "[TS: " .. vim.fn["nvim_treesitter#statusline"](90) as string .. "]"
-- end, "GitGreen")
stl.add({"SyntaxViewer", "Debugging"}, {"Inactive"}, function(): string
	local cursor = a.nvim_win_get_cursor(0) as {number}
	return "  Syntax: " .. vim.fn.synIDattr(vim.fn.synID(cursor[1], cursor[2]+1, 0), "name") as string .. " "
end, "GitGreen")
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
	return ("  Indent: %d "):format(indent / shiftwidth)
end, "GreenInverted")
-- }}}
stl.add({"ActiveSeparator", "Active"}, {"Inactive"}, "%=", "BrightGrayBg")
stl.add({"InactiveSeparator", "Inactive"}, {"Active"}, "%=", "DarkGrayBg")
stl.add({"Shiftwidth", "Tabstop", "Expandtab", "Active"}, {"Inactive"}, function(): string
	local expandtab = a.nvim_buf_get_option(0, "expandtab")
	local num: number
	if expandtab == 1 then
		num = a.nvim_buf_get_option(0, "tabstop") as number
	else
		num = a.nvim_buf_get_option(0, "shiftwidth") as number
	end
	return ("  %s (%d) "):format(expandtab and "spaces" or "tabs", num)
end, "BrightGrayBg")
stl.add({"LineNumber", "NavInfo", "Active", "Inactive"}, {}, " %l/%L:%c ", "CommentInverted")
stl.add({"FilePercent", "NavInfo", "Active", "Inactive"}, {"Debugging"}, "%3p%%", "CommentInverted")
stl.add({"TrailingSpace", "Spaces", "Active", "Inactive"}, {}, " ", "CommentInverted")

map("n", "<F12>", function() stl.toggleTag("Debugging") end)
-- }}}
-- {{{ Other Stuffs
-- {{{ vim-commentary imitation
local commenter = require("euclidian.commenter")
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
-- {{{ appending things
local append = require("euclidian.append")
local getchar = vim.fn.getchar as function(): number
map("n", "<leader>a", function()
	append.toCurrentLine(string.char(getchar()))
end)
map("v", "<leader>a", function()
	local start = (a.nvim_buf_get_mark(0, "<") as {number})[1] - 1
	local finish = (a.nvim_buf_get_mark(0, ">") as {number})[1]
	append.toRange(start, finish, string.char(getchar()))
end)
-- }}}
-- {{{ Window movement/resizing
for mvkey, szkey in unpacker{
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
local function setupTerm()
	local termCmd: string = vim.fn.input("Command to execute in terminal: ") as string
	if #trim(termCmd) == 0 then
		return
	end
	cmd("sp +term")
	local termWin = a.nvim_get_current_win()
	local termBuf = a.nvim_get_current_buf()
	local ok, job: boolean, number = pcall(a.nvim_buf_get_var, 0, "terminal_job_id") as (boolean, number)
	if not ok then
		print("Unable to get terminal job id\n")
		return
	end
	map("n", "<leader>t", function()
		local ok = pcall(vim.fn.chansend, job, termCmd .. "\n")
		if not ok then
			print("[<leader>t] Unable to send command to terminal, (" .. termCmd .. ")")
		end
	end)
	cmd "autocmd BufDelete <buffer> lua require'euclidian.config'.stuff.setupTermMapping()"
end
export.stuff.setupTermMapping = function()
	unmap("n", "<leader>t")
	map("n", "<leader>t", setupTerm)
end

map("n", "<leader>t", setupTerm)
-- }}}
-- {{{ luaprinter binding
map("n", "<leader>lp", function()
	local curBuf = vim.fn.bufnr() as number
	cmd "augroup luaprinter"
	cmd 	("autocmd BufWritePost <buffer=" .. curBuf .. "> lua require('euclidian.luaprinter').runBuffer(" .. curBuf .. ", 10000)")
	cmd 	("autocmd InsertLeave  <buffer=" .. curBuf .. "> lua require('euclidian.luaprinter').runBuffer(" .. curBuf .. ", 1500)")
	cmd "augroup END"
	local fname = a.nvim_buf_get_name(0)
	print("[euclidian.luaprinter] Attached lua printer to buffer", curBuf, "(", fname, ")")
end)
-- }}}
-- }}}

return export
