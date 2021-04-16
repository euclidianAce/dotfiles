
local M <const> = { _exports: {string:function} = {} }

local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local a <const> = vim.api
local uv <const> = vim.loop

local function combinations<A, B>(as: {A}, bs: {B}): function(): A, B
	return coroutine.wrap(function(): A, B
		for _, a in ipairs(as) do
			for _, b in ipairs(bs) do
				coroutine.yield(a, b)
			end
		end
	end) as function(): (A, B)
end

local function ensure_array<T>(t: T | {T}): {T}
	-- for generics `t is T` always compiles to type(t) == "table"
	if type(t) ~= "table" then
		return {t as T}
	elseif t then
		return t as {T}
	else
		return {}
	end
end

local function map(m: vim.Mode | {vim.Mode}, lhs: string | {string}, rhs: string | function)
	for mode, l in combinations(ensure_array(m), ensure_array(lhs)) do
		nvim.setKeymap(mode, l, rhs, {noremap = true, silent = true})
	end
end
local function unmap(m: vim.Mode, lhs: string)
	nvim.delKeymap(m, lhs)
end

local function bufMap(bufid: integer, m: vim.Mode | {vim.Mode}, lhs: string | {string}, rhs: string | function)
	local buf <const> = nvim.Buffer(bufid)
	for mode, l in combinations(ensure_array(m), ensure_array(lhs)) do
		buf:setKeymap(mode, l, rhs, {noremap = true, silent = true})
	end
end

map("n", "<leader>cc", function()
	local cursorPos = a.nvim_win_get_cursor(0)
	require("euclidian.lib.commenter").commentLine(0, cursorPos[1])
end)
local enum OperatorfuncMode -- TODO: put this in the .d.tl
	"line" "char" "block"
end
local commenter <const> = require("euclidian.lib.commenter")
M._exports.commentMotion = function(kind: OperatorfuncMode)
	if kind ~= "line" then return end
	local b <const> = nvim.Buffer()
	commenter.commentRange(
		b.id,
		b:getMark('[')[1] - 1,
		b:getMark(']')[1]
	)
end
M._exports.commentVisualSelection = function()
	local b <const> = nvim.Buffer()
	commenter.commentRange(
		b.id,
		b:getMark('<')[1] - 1,
		b:getMark('>')[1]
	)
end

map(
	"n", "<leader>c",
	[[<cmd>set opfunc=v:lua.euclidian.config.keymaps._exports.commentMotion")<cr>g@]]
)
map("v", "<leader>c", [[:lua require("euclidian.config.keymaps")._exports.commentVisualSelection()<cr>]])

local getchar <const> = vim.fn.getchar as function(): number
local append <const> = require("euclidian.lib.append")

M._exports.appendMotion = function(kind: OperatorfuncMode)
	if kind ~= "line" then return end
	local b <const> = nvim.Buffer()
	append.toRange(
		b:getMark('[')[1] - 1,
		b:getMark(']')[1],
		string.char(getchar()),
		b.id
	)
end
M._exports.appendToVisualSelection = function()
	local b <const> = nvim.Buffer()
	append.toRange(
		b:getMark('<')[1] - 1,
		b:getMark('>')[1],
		string.char(getchar()),
		b.id
	)
end

map(
	"n", "<leader>a",
	[[<cmd>set opfunc=v:lua.euclidian.config.keymaps._exports.appendMotion")<cr>g@]]
)
map("n", "<leader>aa", function()
	append.toCurrentLine(string.char(getchar()))
end)
map("v", "<leader>a", [[:lua require("euclidian.config.keymaps")._exports.appendToVisualSelection()<cr>]])

for _, v in ipairs{
	{"h", "<"},
	{"j", "+"},
	{"k", "-"},
	{"l", ">"},
} do
	local mvkey <const>, szkey <const> = v[1], v[2]
	unmap("n", "<C-W>" .. mvkey)
	map("n", "<C-" .. mvkey .. ">", "<cmd>wincmd " .. mvkey .. "<CR>")
	map("n", "<M-" .. mvkey .. ">", "<C-w>3" .. szkey)
end

map("n", "<leader>k", vim.lsp.diagnostic.show_line_diagnostics)
map("n", "K", vim.lsp.buf.hover)
map("n", "<leader>N", vim.lsp.diagnostic.goto_next)
map("n", "<leader>P", vim.lsp.diagnostic.goto_prev)

map("n", "<leader>fz", require("telescope.builtin").find_files)
map("n", "<leader>g",  require("telescope.builtin").live_grep)

map("n", "<leader>n", "<cmd>noh<cr>")

map("i", "{<CR>", "{}<Esc>i<CR><CR><Esc>kS")
map("i", "(<CR>", "()<Esc>i<CR><CR><Esc>kS")

map("t", "<Esc>", "<C-\\><C-n>")

do -- floating buffer to execute some lua
	local d <const> = dialog.new{
		wid = 75, hei = 30,
		centered = true,
		interactive = true,
		notMinimal = true,
		hidden = true,
	}
	d:setModifiable(true)
	local buf <const> = d.buf

	buf:setOption("ft", "teal")
	buf:setOption("tabstop", 3)
	buf:setOption("shiftwidth", 3)
	buf:setKeymap(
		"n", "<cr>",
		function()
			local lines <const> = d:getLines()
			local txt <const> = table.concat(lines, "\n")

			local chunk <const>, loaderr <const> = loadstring(txt)
			if not chunk then
				a.nvim_err_writeln(loaderr)
				return
			end
			local ok <const>, err <const> = pcall(chunk) as (boolean, string)
			if not ok then
				a.nvim_err_writeln(err)
			end
		end,
		{ silent = true, noremap = true }
	)
	buf:setKeymap(
		"n", "",
		function() d:hide() end,
		{ silent = true, noremap = true }
	)
	map("n", "<leader>lua", function() d:show() end)
end

do -- floatterm
	local d <const> = dialog.new{
		wid = 0.9, hei = 0.85,
		centered = true,
		interactive = true,
		hidden = true,
	}

	local openTerm, hideTerm: function(), function()
	d.buf:setOption("modified", false)
	local bufOpenTerm <const> = vim.schedule_wrap(function()
		vim.fn.termopen("bash")
	end) as function(): nil
	local key <const> = ""

	M._exports.getTermChannel = function(): integer
		return d.buf:getOption("channel")
	end
	M._exports.termSend = function(s: string): boolean
		if not d.buf:isValid() then
			return false
		end
		a.nvim_chan_send(d.buf:getOption("channel"), s)
		return true
	end

	openTerm = function()
		if d.buf:getOption("buftype") ~= "terminal" then
			d.buf:call(bufOpenTerm)
		end
		d:show()
		d.win:setOption("winblend", 8)
	end

	hideTerm = function()
		d:hide()
		map("n", key, openTerm)
	end

	bufMap(d.buf.id, {"t", "n"}, key, hideTerm)
	map("n", key, openTerm)
end

do -- cd dialog
	local d: dialog.Dialog = dialog.new{
		wid = 0.4, hei = 0.2,
		centered = true,
		interactive = true,
		hidden = true,
	}
	map("n", "<leader>cd", function()
		local cwd <const> = vim.loop.cwd()
		local lns <const> = { "== SUPER DUPER WIP ==", "Cwd: " .. cwd }
		for file in uv.fs_scandir_next, uv.fs_scandir(cwd) do
			table.insert(lns, file)
		end
		d:setLines(lns)
		d:show()
	end)
end

return M
