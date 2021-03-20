
local M <const> = { _exports: {string:function} = {} }

local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local a <const> = vim.api

local function map(m: vim.Mode | {vim.Mode}, lhs: string, rhs: string | function)
	if m is vim.Mode then
		nvim.setKeymap(m, lhs, rhs, {noremap = true, silent = true})
	else
		for _, mode in ipairs(m) do
			nvim.setKeymap(mode, lhs, rhs, {noremap = true, silent = true})
		end
	end
end
local function unmap(m: vim.Mode, lhs: string)
	nvim.delKeymap(m, lhs)
end

local function bufMap(bufid: integer, m: string | {string}, lhs: string, rhs: string|function)
	local buf <const> = nvim.Buffer(bufid)
	if m is vim.Mode then
		buf:setKeymap(m, lhs, rhs, {noremap = true, silent = true})
	else
		for _, mode in ipairs(m as {vim.Mode}) do
			buf:setKeymap(mode, lhs, rhs, {noremap = true, silent = true})
		end
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

do
	local d: dialog.Dialog
	local buf: nvim.Buffer
	-- floating buffer to execute some lua
	map("n", "<leader>lua", function()
		d = dialog.centered(75, 30, buf)
		if not buf then
			buf = d.buf
			buf:setOption("ft", "teal")
			buf:setOption("tabstop", 3)
			buf:setOption("shiftwidth", 3)
			buf:setKeymap(
				"n", "<cr>",
				function() M._exports.luaPrompt() end,
				{ silent = true, noremap = true }
			)
			buf:setKeymap(
				"n", "",
				function() d.win:hide() end,
				{ silent = true, noremap = true }
			)
		end
		d:setModifiable(true)
		M._exports.luaPrompt = function()
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
		end
	end)
end

do
	local fBuf, fWin: nvim.Buffer, nvim.Window
	local openTerm, hideTerm: function(), function()

	M._exports.getTermChannel = function(): integer
		return fBuf and fBuf:getOption("channel") as integer
	end
	M._exports.termSend = function(s: string): boolean
		if not fBuf or not fBuf:isValid() then
			return false
		end
		vim.fn.chansend(fBuf:getOption("channel"), s)
		return true
	end
	
	local function incBlend()
		fWin:setOption("winblend", fWin:getOption("winblend") - 8)
	end
	local function decBlend()
		fWin:setOption("winblend", fWin:getOption("winblend") + 8)
	end

	local key <const> = ""

	openTerm = function()
		if fWin and fWin:isValid() then
			a.nvim_set_current_win(fWin.id)
		elseif not (fBuf and fBuf:isValid()) then
			fBuf = nvim.createBuf(true, false)
			local opts <const> =
				dialog.centeredSize(math.huge as integer, math.huge as integer)

			fWin = nvim.openWin(fBuf, true, {
				relative = "editor",
				row = opts.row, col = opts.col, width = opts.wid, height = opts.hei
			})

			fWin:setOption("winblend", 16)

			-- ':h terminal-emulator' says that this prevents it complaining when closing
			-- but it still sometimes does :P
			fBuf:setOption("modified", false)

			nvim.command [[term]]
			bufMap(fBuf.id, {"t", "n"}, key, hideTerm)
			bufMap(fBuf.id, {"t", "n"}, "", decBlend)
			bufMap(fBuf.id, {"t", "n"}, "", incBlend)
		else
			local opts <const> =
				dialog.centeredSize(math.huge as integer, math.huge as integer)

			fWin = nvim.openWin(fBuf, true, {
				relative = "editor",
				row = opts.row, col = opts.col, width = opts.wid, height = opts.hei
			})
		end
	end

	hideTerm = function()
		if fWin:isValid() then
			fWin:hide()
		end
		fWin = nil
		map("n", key, openTerm)
	end

	map("n", key, openTerm)
end

return M
