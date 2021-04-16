
local M <const> = { _exports: {string:function} = {} }

local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local a <const> = vim.api

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
	local d: dialog.Dialog
	local buf: nvim.Buffer
	map("n", "<leader>lua", function()
		d = dialog.centered(75, 30, { interactive = true, notMinimal = true }, buf)
		if not buf then
			buf = d.buf
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
				function()
					d.win:hide()
				end,
				{ silent = true, noremap = true }
			)
		end
		d:setModifiable(true)
	end)
end

do -- floatterm
	local d: dialog.Dialog
	local bufid: nvim.Buffer.Id
	local openTerm, hideTerm: function(), function()

	M._exports.getTermChannel = function(): integer
		return d and d.buf:getOption("channel") as integer
	end
	M._exports.termSend = function(s: string): boolean
		if not (d and d.buf:isValid()) then
			return false
		end
		a.nvim_chan_send(d.buf:getOption("channel") as integer, s)
		return true
	end

	local lastCfg: nvim.Window.Config

	local function editCfg(field: string, val: integer): function()
		return function()
			local c <const> = d.win:getConfig() as table
			local f <const> = c[field] as {boolean:number} | number
			c[field] = (f is number and assert(f) or f[false]) + val
			d.win:setConfig(c as nvim.Window.Config)
			lastCfg = c as nvim.Window.Config
		end
	end

	local resizing = true
	local function makeMap(resizeOpt: string, moveOpt: string, val: integer): function()
		local resize <const> = editCfg(resizeOpt, val)
		local move <const> = editCfg(moveOpt, val)
		return function()
			if resizing then
				resize()
			else
				move()
			end
		end
	end

	local key <const> = ""

	local function getDialog(): dialog.Dialog
		if not nvim.Buffer(bufid):isValid() then bufid = nil end
		local dwin = dialog.centered(0.9, 0.85, { interactive = true }, bufid)
		bufid = dwin.buf.id
		if lastCfg then
			dwin.win:setConfig(lastCfg)
		end
		return dwin
	end

	openTerm = function()
		if d and d.win:isValid() then
			a.nvim_set_current_win(d.win.id)
		elseif not (d and d.buf:isValid()) then
			d = getDialog()
			d.win:setOption("winblend", 8)

			-- ':h terminal-emulator' says that this prevents it complaining when closing
			-- but it still sometimes does :P
			d.buf:setOption("modified", false)
			d.buf:call(vim.schedule_wrap(function()
				vim.fn.termopen("bash")
			end) as function(): nil)
			-- nvim.command [[term]]
			bufMap(d.buf.id, {"t", "n"}, key, hideTerm)

			bufMap(d.buf.id, "n", "<leader>r", function() resizing = not resizing end)
			bufMap(d.buf.id, "n", "<M-h>", makeMap("width", "col", -3))
			bufMap(d.buf.id, "n", "<M-l>", makeMap("width", "col", 3))

			bufMap(d.buf.id, "n", "<M-j>", makeMap("height", "row", 3))
			bufMap(d.buf.id, "n", "<M-k>", makeMap("height", "row", -3))
		else
			d = getDialog()
		end
	end

	hideTerm = function()
		if d and d.win:isValid() then
			d.win:hide()
		end
		map("n", key, openTerm)
	end

	map("n", key, openTerm)
end

return M
