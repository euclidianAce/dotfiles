
local M <const> = { _exports: {string:function} = {} }

local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local a <const> = vim.api
local uv <const> = vim.loop

local function combinations<X, Y>(xs: {X}, ys: {Y}): function(): X, Y
	return coroutine.wrap(function(): X, Y
		for _, x in ipairs(xs) do
			for _, y in ipairs(ys) do
				coroutine.yield(x, y)
			end
		end
	end) as function(): (X, Y)
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
local unmap <const> = nvim.delKeymap

local function bufMap(bufid: integer, m: vim.Mode | {vim.Mode}, lhs: string | {string}, rhs: string | function)
	local buf <const> = nvim.Buffer(bufid)
	for mode, l in combinations(ensure_array(m), ensure_array(lhs)) do
		buf:setKeymap(mode, l, rhs, {noremap = true, silent = true})
	end
end

map("n", "<leader>cc", function()
	require("euclidian.lib.commenter").commentLine(0, nvim.Window():getCursor()[1])
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

map("n", "<leader>c", [[<cmd>set opfunc=v:lua.euclidian.config.keymaps._exports.commentMotion")<cr>g@]])
map("v", "<leader>c", [[:lua require("euclidian.config.keymaps")._exports.commentVisualSelection()<cr>]])

local function getchar(): string
	return string.char(vim.fn.getchar() as integer)
end
local function getchars(): string
	return vim.fn.input("Append Characters:") as string
end
local append <const> = require("euclidian.lib.append")

M._exports.appendCharMotion = function(kind: OperatorfuncMode)
	if kind ~= "line" then return end
	local b <const> = nvim.Buffer()
	append.toRange(
		b:getMark("[")[1],
		b:getMark("]")[1],
		getchar(),
		b.id
	)
end

M._exports.appendCharsMotion = function(kind: OperatorfuncMode)
	if kind ~= "line" then return end
	local b <const> = nvim.Buffer()
	append.toRange(
		b:getMark("[")[1],
		b:getMark("]")[1],
		getchars(),
		b.id
	)
end

M._exports.appendToVisualSelection = function(multiple: boolean)
	local b <const> = nvim.Buffer()
	local inputfn <const> = multiple and getchars or getchar
	append.toRange(
		b:getMark("<")[1],
		b:getMark(">")[1],
		inputfn(),
		b.id
	)
end

-- TODO: entering command mode here seems to be the most convenient way of
-- updating the visual selection marks that these functions rely on. There
-- doesn't seem to be a way to actually get the current visual selection
map("v", "<leader>a", [[:lua require("euclidian.config.keymaps")._exports.appendToVisualSelection(false)<cr>]])
map("v", "<leader>A", [[:lua require("euclidian.config.keymaps")._exports.appendToVisualSelection(true)<cr>]])

map("n", "<leader>a", [[<cmd>set opfunc=v:lua.euclidian.config.keymaps._exports.appendCharMotion")<cr>g@]])
map("n", "<leader>A", [[<cmd>set opfunc=v:lua.euclidian.config.keymaps._exports.appendCharsMotion")<cr>g@]])

map("n", "<leader>aa", function() append.toCurrentLine(getchar()) end)
map("n", "<leader>AA", function() append.toCurrentLine(getchars()) end)

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

	local function configureBuf(buf: nvim.Buffer)
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
	end

	map("n", "<leader>lua", function()
		configureBuf(d:ensureBuf())
		d:show()
	end)
end

do -- floatterm
	local d <const> = dialog.new{
		wid = 0.9, hei = 0.85,
		centered = true,
		interactive = true,
		hidden = true,
	}
	local buf <const> = d:ensureBuf()

	buf:setOption("modified", false)
	local bufOpenTerm <const> = vim.schedule_wrap(function()
		vim.fn.termopen("bash")
	end)
	local key <const> = ""

	M._exports.getTermChannel = function(): integer
		return buf:getOption("channel")
	end
	M._exports.termSend = function(s: string): boolean
		if not buf:isValid() then
			return false
		end
		a.nvim_chan_send(buf:getOption("channel"), s)
		return true
	end

	local function openTerm()
		if buf:getOption("buftype") ~= "terminal" then
			buf:call(bufOpenTerm)
		end
		d:show():win():setOption("winblend", 8)
	end

	local function hideTerm()
		d:hide()
		map("n", key, openTerm)
	end

	bufMap(buf.id, {"t", "n"}, key, hideTerm)
	map("n", key, openTerm)
end

do -- cd dialog
	-- TODO: turn this into a telescope lens
	-- TODO: dialog api should have some concept of a window/dialog group

	local input, result: dialog.Dialog, dialog.Dialog
	local currentlyMatching = false
	local function init()
		if not input then
			input = dialog.new{
				row = .25,
				wid = .4, hei = 1,
				centered = { horizontal = true },
				ephemeral = true,
				interactive = true,
			}
		end
		if not result then
			local cfg <const> = input:win():getConfig()
			local row <const> = (cfg.row as {boolean:integer})[false] + cfg.height + 2
			result = dialog.new{
				row = row,
				wid = .4, hei = .2,
				centered = { horizontal = true },
				ephemeral = true,
			}
		end
	end
	local function close()
		currentlyMatching = false
		if input then input:close() end input = nil
		if result then result:close() end result = nil
	end

	local function ls(dirname: string): {string}
		local res = {}
		local scanner = uv.fs_scandir(dirname)
		if scanner then
			for f in uv.fs_scandir_next, scanner do
				table.insert(res, f)
			end
		end
		return res
	end

	local function cdDialog()
		init()
		result:show(true)
		input:show()
		nvim.command[[startinsert]]

		local b <const> = input:ensureBuf()
		input:setModifiable(true)

		local function currentInput(): string, string
			local ln <const> = input:getLine(1)
			local head <const>, tail <const> = ln:match("(.*)/([^/]*)$")
			if not tail then
				return "", ln
			end
			return head, tail
		end

		local function currentDir(): string
			local components <const>: {string} = {}
			for _, path in ipairs{ uv.cwd(), (currentInput()) } do
				for chunk in vim.gsplit(path, "/", true) do
					if chunk == ".." then
						table.remove(components)
					else
						table.insert(components, chunk)
					end
				end
			end

			return table.concat(components, "/")
		end

		local function isDir(path: string): boolean
			local stat <const> = uv.fs_stat(path)
			return stat and stat.type == "directory"
		end

		b:setKeymap("n", "<esc>", close, {})
		b:setKeymap("i", "<esc>", function() nvim.command[[stopinsert]] close() end, {})
		b:setKeymap("i", "<cr>", function()
			local res <const> = input:getLine(1)
			close()
			nvim.command [[stopinsert]]
			nvim.command("cd " .. res)
			print("cd: " .. res)
		end, {})

		local function updateResultText()
			local cd <const> = currentDir()
			if currentlyMatching then
				local head <const>, tail <const> = currentInput()
				local matches <const> = {}
				local patt <const> = "^" .. vim.pesc(tail)
				for _, v in ipairs(ls(cd)) do
					if v:match(patt) and isDir((#head > 0 and head .. "/" or "") .. v) then
						table.insert(matches, v)
					end
				end
				if #matches == 1 then
					currentlyMatching = false
					vim.schedule(function()
						local newLn <const> = (#head > 0 and head .. "/" or "") .. matches[1] .. "/"
						input:setLines{ newLn }
						input:setCursor(1, #newLn)
					end)
				else
					vim.schedule(function()
						result:setLines{
							"ls: " .. cd .. (cd:match("/$") and "" or "/") .. "...",
							("-- %d Director%s matching %q --"):format(
								#matches,
								#matches == 1 and "y" or "ies",
								tail
							)
						}
						result:appendLines(matches)
					end)
				end
			else
				local dirs <const>, files <const> = {}, {}
				for _, v in ipairs(ls(cd)) do
					table.insert(isDir(cd .. "/" .. v) and dirs or files, v)
				end
				vim.schedule(function()
					result:setLines{
						"ls: " .. cd,
						("-- %d Director%s --"):format(#dirs, #dirs == 1 and "y" or "ies")
					}
					result:appendLines(dirs)
					result:appendLines{
						("-- %d File%s --"):format(#files, #files == 1 and "" or "s")
					}
					result:appendLines(files)
				end)
			end
		end

		b:setKeymap("i", "<tab>", function()
			currentlyMatching = true
			updateResultText()
			if currentlyMatching then
				b:setKeymap("i", "<bs>", function()
					b:delKeymap("i", "<bs>")
					currentlyMatching = false
					updateResultText()
				end, {})
			end
		end, {})

		b:attach(true, { on_lines = updateResultText })

		updateResultText()
	end

	map("n", "<leader>cd", cdDialog)
end

-- font resizing
local function getGuiFontInfo(): string, string
	return (a.nvim_get_option("guifont") as string):match("^(.*:h)(%d+)$")
end
map("n", "<S-Up>", function()
	local name <const>, size <const> = getGuiFontInfo()
	a.nvim_set_option("guifont", name .. tostring(tonumber(size) + 2))
end)
map("n", "<S-Down>", function()
	local name <const>, size <const> = getGuiFontInfo()
	a.nvim_set_option("guifont", name .. tostring(tonumber(size) - 2))
end)

return M
