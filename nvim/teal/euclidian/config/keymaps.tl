
local M <const> = { _exports: table = {} }

local util <const> = require("euclidian.lib.util")
local keymapper <const> = require("euclidian.lib.keymapper")
local a <const> = vim.api
local cmdf <const>, trim <const> = util.cmdf, util.trim

local map = function(m: string, lhs: string, rhs: string|function)
	keymapper.map(m, lhs, rhs, {noremap = true, silent = true})
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
map("v", "<leader>a", function()
	local start <const> = a.nvim_buf_get_mark(0, "<")[1] - 1
	local finish <const> = a.nvim_buf_get_mark(0, ">")[1]
	require("euclidian.lib.append").toRange(start, finish, string.char(getchar()))
end)
for mvkey, szkey in util.unpacker{
	{"h", "<"},
	{"j", "+"},
	{"k", "-"},
	{"l", ">"}}
do
	unmap("n", "<C-W>" .. mvkey)
	map("n", "<C-" .. mvkey .. ">", ":wincmd " .. mvkey .. "<CR>")
	map("n", "<M-" .. mvkey .. ">", "<C-w>3" .. szkey)
	map("n", "<C-w>" .. mvkey, ":echoerr 'stop that'<CR>")
end

local function setupTerm() -- TODO: make this a floating terminal for funsies
	local termCmd <const> = vim.fn.input("Command to execute in terminal: ") as string
	if trim(termCmd) == "" then
		return
	end
	local currentWin <const> = a.nvim_get_current_win()
	cmdf [[sp +term]]

	local ok, job: boolean, number = pcall(a.nvim_buf_get_var, 0, "terminal_job_id") as (boolean, number)
	if not ok then
		print("Unable to get terminal job id\n")
		return
	end
	map("n", "<leader>t", function()
		ok = pcall(vim.fn.chansend, job, termCmd .. "\n")
		if not ok then
			print("Unable to send command to terminal, (" .. termCmd .. ")")
		end
	end)
	cmdf [[autocmd BufDelete <buffer> lua require'euclidian.config.keymaps'._exports.setupTermMapping()]]
	a.nvim_set_current_win(currentWin)
end
M._exports.setupTermMapping = function()
	unmap("n", "<leader>t")
	map("n", "<leader>t", setupTerm)
end

map("n", "<leader>t", setupTerm)
map("n", "<leader>lp", require("euclidian.lib.luaprinter").attach)
map("n", "<leader>ll", function()
	require("euclidian.lib.luaprinter").getLine(a.nvim_win_get_cursor(0)[1])
end)

map("n", "<leader>k", vim.lsp.diagnostic.show_line_diagnostics)

local r <const> = require
local teleBuiltin <const> = r("telescope.builtin") as {string:function()}
map("n", "<leader>fz", teleBuiltin.find_files)
map("n", "<leader>g",  teleBuiltin.live_grep)

map("n", "<leader>s", require("euclidian.lib.snippet").start)

map("n", "<leader>n", ":noh<CR>")

map("i", "{<CR>", "{}<Esc>i<CR><CR><Esc>kS")
map("i", "(<CR>", "()<Esc>i<CR><CR><Esc>kS")

map("t", "<Esc>", "<C-\\><C-n>")

return M
