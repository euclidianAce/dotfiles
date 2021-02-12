
local M <const> = { _exports: table = {} }

local keymapper <const> = require("euclidian.lib.keymapper")
local window <const> = require("euclidian.lib.window")
local a <const> = vim.api

local util <const> = require("euclidian.lib.util")
local cmdf <const>, unpacker <const>
	= util.nvim.cmdf, util.tab.unpacker

local map = function(m: string, lhs: string, rhs: string|function)
	keymapper.map(m, lhs, rhs, {noremap = true, silent = true})
end
local bufMap = function(buf: number, m: string | {string}, lhs: string, rhs: string|function)
	if m is string then
		keymapper.bufMap(buf, m, lhs, rhs, {noremap = true, silent = true})
	else
		for _, v in ipairs(m) do
			keymapper.bufMap(buf, v, lhs, rhs, {noremap = true, silent = true})
		end
	end
end
local unmap <const> = keymapper.unmap

map("n", "<leader>cc", function()
	local cursorPos: {number} = a.nvim_win_get_cursor(0)
	require("euclidian.lib.commenter").commentLine(0, cursorPos[1])
end)
local enum OperatorfuncMode -- TODO: put this in the .d.tl
	"line" "char" "block"
end
M._exports.commentMotion = function(kind: OperatorfuncMode)
	if kind ~= "line" then return end
	local l1 <const> = a.nvim_buf_get_mark(0, '[')[1]
	local l2 <const> = a.nvim_buf_get_mark(0, ']')[1]
	require("euclidian.lib.commenter").commentRange(0, l1-1, l2)
end

map(
	"n", "<leader>c",
	[[:set opfunc=v:lua.euclidian.config.keymaps._exports.commentMotion")<cr>g@]]
)

local getchar <const> = vim.fn.getchar as function(): number
map("n", "<leader>a", function()
	require("euclidian.lib.append").toCurrentLine(string.char(getchar()))
end)

for mvkey, szkey in unpacker{
	{"h", "<"},
	{"j", "+"},
	{"k", "-"},
	{"l", ">"}}
do
	unmap("n", "<C-W>" .. mvkey)
	map("n", "<C-" .. mvkey .. ">", ":wincmd " .. mvkey .. "<CR>")
	map("n", "<M-" .. mvkey .. ">", "<C-w>3" .. szkey)
end

map("n", "<leader>k", vim.lsp.diagnostic.show_line_diagnostics)
map("n", "K", vim.lsp.buf.hover)
map("n", "<leader>N", vim.lsp.diagnostic.goto_next)
map("n", "<leader>P", vim.lsp.diagnostic.goto_prev)

map("n", "<leader>fz", require("telescope.builtin").find_files)
map("n", "<leader>g",  require("telescope.builtin").live_grep)

map("n", "<leader>s", require("euclidian.lib.snippet").start)

map("i", "{<CR>", "{}<Esc>i<CR><CR><Esc>kS")
map("i", "(<CR>", "()<Esc>i<CR><CR><Esc>kS")

map("t", "<Esc>", "<C-\\><C-n>")

do
	local lastText = { "-- Enter lua code here:", "-- Press <CR> in normal mode to run it and close this window", "" }
	-- floating buffer to execute some lua
	map("n", "<leader>lua", function()
		local d <const> = require("euclidian.lib.dialog").centered()
		d:setBufOpt("ft", "teal")
		d:setBufOpt("tabstop", 3)
		d:setModifiable(true)
		cmdf "startinsert"
		d:addKeymap("n", "<CR>", "<cmd>lua require'euclidian.config.keymaps'._exports.luaPrompt()<cr>", { silent = true, noremap = true })
		if lastText[#lastText] ~= "" then
			table.insert(lastText, "")
		end
		d:setLines(lastText)
		d:setCursor(#lastText, 0)
		M._exports.luaPrompt = function()
			local lines = d:getLines()
			lastText = lines
			local txt <const> = table.concat(lines, "\n")

			local chunk <const> = loadstring(txt)
			local ok, err = pcall(chunk) as (boolean, string)
			if not ok then
				a.nvim_err_writeln(err)
			end
			d:close()
			M._exports.luaPrompt = nil
		end
	end)
end

do
	local floatyBuf, floatyWin: window.BufId, window.WinId
	local openTerm: function
	local hideTerm: function
	local function incBlend()
		local blend = a.nvim_win_get_option(floatyWin, "winblend") as number
		a.nvim_win_set_option(floatyWin, "winblend", blend - 8)
	end
	local function decBlend()
		local blend = a.nvim_win_get_option(floatyWin, "winblend") as number
		a.nvim_win_set_option(floatyWin, "winblend", blend + 8)
	end

	openTerm = function()
		if floatyWin and a.nvim_win_is_valid(floatyWin) then
			a.nvim_set_current_win(floatyWin)
		elseif not (floatyBuf and a.nvim_buf_is_valid(floatyBuf)) then
			floatyWin, floatyBuf = window.centeredFloat(math.huge, math.huge)
			a.nvim_win_set_option(floatyWin, "winblend", 16)
			a.nvim_buf_set_option(floatyBuf, "modified", false)
			cmdf [[term]]
			bufMap(floatyBuf, {"t", "n"}, "", hideTerm)
			bufMap(floatyBuf, {"t", "n"}, "", decBlend)
			bufMap(floatyBuf, {"t", "n"}, "", incBlend)
		else
			floatyWin = window.centeredFloat(math.huge, math.huge, floatyBuf)
		end
		vim.schedule(function()
			cmdf "startinsert"
		end)
	end
	hideTerm = function()
		if a.nvim_win_is_valid(floatyWin) then
			a.nvim_set_current_win(floatyWin)
			vim.schedule(function()
				-- no api function to just hide a window?, so this feels super hacky
				cmdf "hide"
			end)
		end
		floatyWin = nil
		map("n", "", openTerm)
	end
	map("n", "", openTerm)
	map("n", "<leader>n", "<cmd>noh<cr>")
end

return M
