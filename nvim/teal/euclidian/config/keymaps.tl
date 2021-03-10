
local M <const> = { _exports: table = {} }

local nvim <const> = require("euclidian.lib.nvim")
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
M._exports.commentMotion = function(kind: OperatorfuncMode)
	if kind ~= "line" then return end
	local b <const> = nvim.Buffer()
	require("euclidian.lib.commenter").commentRange(
		0,
		b:getMark('[')[1] - 1,
		b:getMark(']')[1]
	)
end

map(
	"n", "<leader>c",
	[[<cmd>set opfunc=v:lua.euclidian.config.keymaps._exports.commentMotion")<cr>g@]]
)

local getchar <const> = vim.fn.getchar as function(): number
map("n", "<leader>a", function()
	require("euclidian.lib.append").toCurrentLine(string.char(getchar()))
end)

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
	local lastText = { "-- Press <CR> in normal mode to run", "-- Enter lua code here:", "" }
	-- floating buffer to execute some lua
	map("n", "<leader>lua", function()
		local d <const> = require("euclidian.lib.dialog").centered(75, 30)
		d.buf:setOption("ft", "teal")
		d.buf:setOption("tabstop", 3)
		d.buf:setOption("shiftwidth", 3)
		d:setModifiable(true)
		d:addKeymap("n", "<CR>", "<cmd>lua require'euclidian.config.keymaps'._exports.luaPrompt()<cr>", { silent = true, noremap = true })
		if lastText[#lastText] ~= "" then
			table.insert(lastText, "")
		end
		d:setLines(lastText)
		d:setCursor(#lastText, 0)
		nvim.command([[autocmd BufDelete <buffer=%d> lua require'euclidian.config.keymap'._exports.luaPrompt = nil<cr>]], d.buf.id)
		M._exports.luaPrompt = function()
			local lines = d:getLines()
			lastText = lines
			local txt <const> = table.concat(lines, "\n")

			local chunk <const> = loadstring(txt)
			local ok, err = pcall(chunk) as (boolean, string)
			if not ok then
				a.nvim_err_writeln(err)
			end
		end
	end)
end

do
	local fBuf, fWin: nvim.Buffer, nvim.Window
	local openTerm, hideTerm: function(), function()

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
			local col, row, wid, hei =
				require("euclidian.lib.dialog").centeredSize(math.huge as integer, math.huge as integer)

			fWin = nvim.openWin(fBuf, true, {
				relative = "editor",
				row = row, col = col, width = wid, height = hei
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
			local col, row, wid, hei =
				require("euclidian.lib.dialog").centeredSize(math.huge as integer, math.huge as integer)

			fWin = nvim.openWin(fBuf, true, {
				relative = "editor",
				row = row, col = col, width = wid, height = hei
			})
		end
	end

	hideTerm = function()
		if fWin:isValid() then
			local id <const> = fWin.id
			vim.schedule(function()
				a.nvim_set_current_win(id)
				nvim.command [[hide]]
			end)
		end
		fWin = nil
		map("n", key, openTerm)
	end

	map("n", key, openTerm)
end

return M
