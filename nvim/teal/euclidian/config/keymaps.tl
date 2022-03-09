local dialog <const> = require("euclidian.lib.dialog")
local input <const> = require("euclidian.lib.input")
local nvim <const> = require("euclidian.lib.nvim")
local z <const> = require("euclidian.lib.azync")

local uv <const> = vim.loop

local map <const> = function(modes: string | {string}, lhs: string, rhs: string | function, opts: vim.keymap.Opts)
	vim.keymap.set(modes, lhs, rhs, opts or { silent = true })
end

local commenter <const> = require("euclidian.lib.commenter")
map("n", "<leader>cc", function()
	commenter.commentLine(0, nvim.Window():getCursor()[1])
end)
local enum OperatorfuncMode -- TODO: put this in the .d.tl
	"line" "char" "block"
end
__euclidian.commentMotion = function(kind: OperatorfuncMode)
	if kind ~= "line" then return end
	local b <const> = nvim.Buffer()
	commenter.commentRange(
		b.id,
		b:getMark('[')[1] - 1,
		b:getMark(']')[1]
	)
end
__euclidian.commentVisualSelection = function()
	local b <const> = nvim.Buffer()
	commenter.commentRange(
		b.id,
		b:getMark('<')[1] - 1,
		b:getMark('>')[1]
	)
end

map("n", "<leader>c", [[<cmd>set opfunc=v:lua.__euclidian.commentMotion")<cr>g@]])
map("v", "<leader>c", [[:lua __euclidian.commentVisualSelection()<cr>]])

local function getchar(): string
	return string.char(vim.fn.getchar() as integer)
end
local append <const> = require("euclidian.lib.append")

__euclidian.appendCharMotion = function(kind: OperatorfuncMode)
	if kind ~= "line" then return end
	local b <const> = nvim.Buffer()
	append.toRange(
		b:getMark("[")[1],
		b:getMark("]")[1],
		getchar(),
		b.id
	)
end

__euclidian.appendCharsMotion = function(kind: OperatorfuncMode)
	if kind ~= "line" then return end
	local b <const> = nvim.Buffer()
	local open <const> = b:getMark("[")[1]
	local close <const> = b:getMark("]")[1]
	vim.ui.input({ prompt = "Append Characters: " }, function(userinput: string)
		if userinput then
			append.toRange(open, close, userinput, b.id)
		end
	end)
end

__euclidian.appendToVisualSelection = function(multiple: boolean)
	local b <const> = nvim.Buffer()
	local open <const> = b:getMark("<")[1]
	local close <const> = b:getMark(">")[1]
	if multiple then
		vim.ui.input({ prompt = "Append Characters: " }, function(userinput: string)
			if userinput then
				append.toRange(open, close, userinput, b.id)
			end
		end)
	else
		local c <const> = getchar()
		if c ~= "" then
			append.toRange(open, close, c, b.id)
		end
	end
end

-- TODO: entering command mode here seems to be the most convenient way of
-- updating the visual selection marks that these functions rely on. There
-- doesn't seem to be a way to actually get the current visual selection
map("v", "<leader>a", [[:lua __euclidian.appendToVisualSelection(false)<cr>]])
map("v", "<leader>A", [[:lua __euclidian.appendToVisualSelection(true)<cr>]])

map("n", "<leader>a", [[<cmd>set opfunc=v:lua.__euclidian.appendCharMotion")<cr>g@]])
map("n", "<leader>A", [[<cmd>set opfunc=v:lua.__euclidian.appendCharsMotion")<cr>g@]])

map("n", "<leader>aa", function() append.toCurrentLine(getchar()) end)
map("n", "<leader>AA", function()
	vim.ui.input({ prompt = "Append Characters:" }, function(userinput: string)
		if userinput then
			append.toCurrentLine(userinput)
		end
	end)
end)

local function floatingConfig(win: nvim.Window): nvim.Window, nvim.Window.Config
	win = win or nvim.Window()
	local cfg <const> = win:getConfig()
	if cfg.relative as boolean or cfg.external then
		-- normalize row and column
		cfg.row = (cfg.row as {any:integer})[vim.val_idx]
		cfg.col = (cfg.col as {any:integer})[vim.val_idx]
		return win, cfg
	end
end

for _, v in ipairs{
	{"h", "<"},
	{"j", "+"},
	{"k", "-"},
	{"l", ">"},
} do
	local mvkey <const>, szkey <const> = v[1], v[2]
	map("n", "<C-" .. mvkey .. ">", "<cmd>wincmd " .. mvkey .. "<CR>")
	map("n", "<M-" .. mvkey .. ">", "<C-w>3" .. szkey)
	map("n", "<M-S-" .. mvkey .. ">", function()
		local win <const>, cfg <const> = floatingConfig()
		if not cfg then return end
		if mvkey == "h" then
			cfg.col = cfg.col - 2
		elseif mvkey == "j" then
			cfg.row = cfg.row + 3
		elseif mvkey == "k" then
			cfg.row = cfg.row - 2
		elseif mvkey == "l" then
			cfg.col = cfg.col + 3
		end
		win:setConfig(cfg)
	end)
end

map("n", "K", vim.lsp.buf.hover)
map("n", "<leader>N", vim.diagnostic.goto_next)
map("n", "<leader>P", vim.diagnostic.goto_prev)
map("n", "<leader>k", vim.diagnostic.open_float)

map("n", "<leader>fz", function() require("telescope.builtin").find_files() end)
map("n", "<leader>gr",  function() require("telescope.builtin").live_grep() end)
map("n", "<leader>g*",  function()
	require("telescope.builtin").grep_string{ search = vim.fn.expand("<cword>") as string }
end)

map("n", "<leader>n", "<cmd>noh<cr>")

map("i", "{<CR>", "{}<Esc>i<CR><CR><Esc>kS")
map("i", "(<CR>", "()<Esc>i<CR><CR><Esc>kS")
map("i", "<C-W>", "<C-S-W>")

map("t", "<Esc>", "<C-\\><C-n>")

map({"i", "n"}, "<M-n>", function()
	local win <const>, buf <const> = nvim.winBuf()
	local cursorPos <const> = win:getCursor()
	local line <const> = buf:getLines(cursorPos[1] - 1, cursorPos[1], false)[1]

	local cursorWord = { line:find("%S+", cursorPos[2]) }
		as {integer, integer}
	if not cursorWord[1] then return end

	local prevWord = { line:sub(1, cursorWord[1]):find("%S+()%s*()%S+$") }
		as {integer, integer, integer, integer}

	local cRange <const> = { line:sub(prevWord[4], -1):find("%S+") }
	cRange[1] = cRange[1] + prevWord[4] - 1
	cRange[2] = cRange[2] + prevWord[4] - 1
	local pRange <const> = { prevWord[1], prevWord[3] - 1 }

	local row <const> = cursorPos[1] - 1
	buf:setText(
		row,
		cRange[1]-1,
		row,
		cRange[2],
		{ line:sub(pRange[1], pRange[2]) }
	)

	buf:setText(
		row,
		pRange[1]-1,
		row,
		pRange[2],
		{ line:sub(cRange[1], cRange[2]) }
	)

	local mode = nvim.api.getMode().mode as string
	local pos <const> = {cursorPos[1], cRange[2] - (mode == "i" and 0 or 1)}
	win:setCursor(pos)
end)

map("n", "<leader>head", z.asyncFn(function()
	local buf <const> = nvim.Buffer()
	local lines = buf:getLines(0, -1, false)
	if #lines ~= 1 or lines[1] ~= "" then
		nvim.api.errWriteln("Cannot insert header guard: Buffer is not empty")
		return
	end
	local guard = input.input{ prompt = "Insert Header Guard: " }
	if not guard then return end
	guard = guard:upper()
	if not guard:match("_H$") then
		guard = guard .. "_H"
	end
	guard = guard:gsub("%s", "_")
	buf:setLines(0, -1, false, {
		"#ifndef " .. guard,
		"#define " .. guard,
		"",
		"#endif // " .. guard,
	})
end))

map("n", "<leader>stb", z.asyncFn(function()
	local buf <const> = nvim.Buffer()
	local lines = buf:getLines(0, -1, false)
	if #lines ~= 1 or lines[1] ~= "" then
		nvim.api.errWriteln("Cannot insert STB style guard: Buffer is not empty")
		return
	end
	local guard = input.input{ prompt = "Insert STB style guard: " }
	if not guard then return end

	local normalized <const> = guard:upper():gsub("%s", "_")
	local header <const> = normalized .. "_H"
	local impl <const> = normalized .. "_IMPLEMENTATION"
	guard = guard:gsub("%s", "_")
	buf:setLines(0, -1, false, {
		"#ifndef " .. header,
		"#define " .. header,
		"",
		"#endif /* " .. header .. " */",
		"",
		"#ifdef " .. impl,
		"#endif /* " .. impl .. " */",
	})
end))

do
	local function execBuffer(b: nvim.Buffer)
		b = b or nvim.Buffer()
		local lines <const> = b:getLines(0, -1, false)
		local txt <const> = table.concat(lines, "\n")

		local chunk <const>, loaderr <const> = loadstring(txt)
		if not chunk then
			nvim.api.errWriteln(loaderr)
			return
		end
		local ok <const>, err <const> = pcall(chunk) as (boolean, string)
		if not ok then
			nvim.api.errWriteln(err)
		end
	end

	map("n", "<leader>L", execBuffer)
end

do -- cd dialog
	-- TODO: turn this into a telescope lens
	local pathSeparator <const> = package.config:sub(1, 1)
	local inputDialog, result: dialog.Dialog, dialog.Dialog
	local currentlyMatching = false
	local function init()
		if not inputDialog then
			inputDialog = dialog.new{
				row = .25,
				wid = .4, hei = 1,
				centered = { horizontal = true },
				ephemeral = true,
				interactive = true,
			}
		end
		if not result then
			local cfg <const> = inputDialog:win():getConfig()
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
		if inputDialog then inputDialog:close() end inputDialog = nil
		if result then result:close() end result = nil
	end

	local function ls(dirname: string): {string}
		local res <const> = {}
		local scanner <const> = uv.fs_scandir(dirname)
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
		inputDialog:show()
		nvim.command[[startinsert]]

		result:win():setOption("cursorline", true)
		result:win():setOption("cursorlineopt", "line")

		local b <const> = inputDialog:ensureBuf()
		inputDialog:setModifiable(true)

		local function currentInput(): string, string
			local ln <const> = inputDialog:getLine(1)
			local head <const>, tail <const> = ln:match("(.*)" .. pathSeparator .. "([^" .. pathSeparator .. "]*)$")
			if not tail then
				return "", ln
			end
			return head, tail
		end

		local function currentDir(): string
			local components <const>: {string} = {}
			for _, path in ipairs{ uv.cwd(), (currentInput()) } do
				for chunk in vim.gsplit(path, pathSeparator, true) do
					if chunk == ".." then
						table.remove(components)
					else
						table.insert(components, chunk)
					end
				end
			end

			return table.concat(components, pathSeparator)
		end

		local function isDir(path: string): boolean
			local stat <const> = uv.fs_stat(path)
			return stat and stat.type == "directory"
		end

		b:setKeymap("i", "<c-n>", function()
			local win <const> = result:win()
			local cursor = win:getCursor()
			cursor[1] = cursor[1] + 1
			pcall(function() win:setCursor(cursor) end)
		end, {})

		b:setKeymap("i", "<c-p>", function()
			local win <const> = result:win()
			local cursor = win:getCursor()
			cursor[1] = cursor[1] - 1
			pcall(function() win:setCursor(cursor) end)
		end, {})

		local function setInput(ln: string)
			inputDialog:setLines{ ln }
			vim.schedule(function() inputDialog:setCursor(1, #ln) end)
		end

		b:setKeymap("i", "<c-y>", function()
			local new = currentInput()
			local compl <const> = result:getCurrentLine()
			if #new > 0 then
				new = new .. pathSeparator
			end
			setInput(new .. compl .. pathSeparator)
		end, {})

		b:setKeymap("n", "<esc>", close, {})
		b:setKeymap("i", "<esc>", function() nvim.command("stopinsert") close() end, {})
		b:setKeymap("i", "<cr>", function()
			local res <const> = inputDialog:getLine(1)
			close()
			nvim.command("stopinsert")
			nvim.command("tcd %s", res)
			print("tcd: " .. res)
		end, {})

		local function updateResultText()
			local cd <const> = currentDir()
			if currentlyMatching then
				local head <const>, tail <const> = currentInput()
				local matches <const> = {}
				local patt <const> = "^" .. vim.pesc(tail)
				for _, v in ipairs(ls(cd)) do
					if v:match(patt) and isDir((#head > 0 and head .. pathSeparator or "") .. v) then
						table.insert(matches, v)
					end
				end
				if #matches == 1 then
					currentlyMatching = false
					vim.schedule(function()
						local newLn <const> = (#head > 0 and head .. pathSeparator or "") .. matches[1] .. pathSeparator
						setInput(newLn)
					end)
				else
					vim.schedule(function()
						result:setLines{
							"ls: " .. cd .. (cd:match(pathSeparator .. "$") and "" or pathSeparator) .. "...",
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
					table.insert(isDir(cd .. pathSeparator .. v) and dirs or files, v)
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
