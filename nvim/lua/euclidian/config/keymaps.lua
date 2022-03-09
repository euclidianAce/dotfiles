local dialog = require("euclidian.lib.dialog")
local input = require("euclidian.lib.input")
local nvim = require("euclidian.lib.nvim")
local z = require("euclidian.lib.azync")

local uv = vim.loop

local map = function(modes, lhs, rhs, opts)
   vim.keymap.set(modes, lhs, rhs, opts or { silent = true })
end

local commenter = require("euclidian.lib.commenter")
map("n", "<leader>cc", function()
   commenter.commentLine(0, nvim.Window():getCursor()[1])
end)
local OperatorfuncMode = {}


__euclidian.commentMotion = function(kind)
   if kind ~= "line" then return end
   local b = nvim.Buffer()
   commenter.commentRange(
   b.id,
   b:getMark('[')[1] - 1,
   b:getMark(']')[1])

end
__euclidian.commentVisualSelection = function()
   local b = nvim.Buffer()
   commenter.commentRange(
   b.id,
   b:getMark('<')[1] - 1,
   b:getMark('>')[1])

end

map("n", "<leader>c", [[<cmd>set opfunc=v:lua.__euclidian.commentMotion")<cr>g@]])
map("v", "<leader>c", [[:lua __euclidian.commentVisualSelection()<cr>]])

local function getchar()
   return string.char(vim.fn.getchar())
end
local append = require("euclidian.lib.append")

__euclidian.appendCharMotion = function(kind)
   if kind ~= "line" then return end
   local b = nvim.Buffer()
   append.toRange(
   b:getMark("[")[1],
   b:getMark("]")[1],
   getchar(),
   b.id)

end

__euclidian.appendCharsMotion = function(kind)
   if kind ~= "line" then return end
   local b = nvim.Buffer()
   local open = b:getMark("[")[1]
   local close = b:getMark("]")[1]
   vim.ui.input({ prompt = "Append Characters: " }, function(userinput)
      if userinput then
         append.toRange(open, close, userinput, b.id)
      end
   end)
end

__euclidian.appendToVisualSelection = function(multiple)
   local b = nvim.Buffer()
   local open = b:getMark("<")[1]
   local close = b:getMark(">")[1]
   if multiple then
      vim.ui.input({ prompt = "Append Characters: " }, function(userinput)
         if userinput then
            append.toRange(open, close, userinput, b.id)
         end
      end)
   else
      local c = getchar()
      if c ~= "" then
         append.toRange(open, close, c, b.id)
      end
   end
end




map("v", "<leader>a", [[:lua __euclidian.appendToVisualSelection(false)<cr>]])
map("v", "<leader>A", [[:lua __euclidian.appendToVisualSelection(true)<cr>]])

map("n", "<leader>a", [[<cmd>set opfunc=v:lua.__euclidian.appendCharMotion")<cr>g@]])
map("n", "<leader>A", [[<cmd>set opfunc=v:lua.__euclidian.appendCharsMotion")<cr>g@]])

map("n", "<leader>aa", function() append.toCurrentLine(getchar()) end)
map("n", "<leader>AA", function()
   vim.ui.input({ prompt = "Append Characters:" }, function(userinput)
      if userinput then
         append.toCurrentLine(userinput)
      end
   end)
end)

for _, v in ipairs({
      { "h", "<" },
      { "j", "+" },
      { "k", "-" },
      { "l", ">" },
   }) do
   local mvkey, szkey = v[1], v[2]
   map("n", "<C-" .. mvkey .. ">", "<cmd>wincmd " .. mvkey .. "<CR>")
   map("n", "<M-" .. mvkey .. ">", "<C-w>3" .. szkey)
end

map("n", "K", vim.lsp.buf.hover)
map("n", "<leader>N", vim.diagnostic.goto_next)
map("n", "<leader>P", vim.diagnostic.goto_prev)
map("n", "<leader>k", vim.diagnostic.open_float)

map("n", "<leader>fz", function() require("telescope.builtin").find_files() end)
map("n", "<leader>gr", function() require("telescope.builtin").live_grep() end)
map("n", "<leader>g*", function()
   require("telescope.builtin").grep_string({ search = vim.fn.expand("<cword>") })
end)

map("n", "<leader>n", "<cmd>noh<cr>")

map("i", "{<CR>", "{}<Esc>i<CR><CR><Esc>kS")
map("i", "(<CR>", "()<Esc>i<CR><CR><Esc>kS")
map("i", "<C-W>", "<C-S-W>")

map("t", "<Esc>", "<C-\\><C-n>")

map({ "i", "n" }, "<M-n>", function()
   local win, buf = nvim.winBuf()
   local cursorPos = win:getCursor()
   local line = buf:getLines(cursorPos[1] - 1, cursorPos[1], false)[1]

   local cursorWord = { line:find("%S+", cursorPos[2]) }

   if not cursorWord[1] then return end

   local prevWord = { line:sub(1, cursorWord[1]):find("%S+()%s*()%S+$") }


   local cRange = { line:sub(prevWord[4], -1):find("%S+") }
   cRange[1] = cRange[1] + prevWord[4] - 1
   cRange[2] = cRange[2] + prevWord[4] - 1
   local pRange = { prevWord[1], prevWord[3] - 1 }

   local row = cursorPos[1] - 1
   buf:setText(
   row,
   cRange[1] - 1,
   row,
   cRange[2],
   { line:sub(pRange[1], pRange[2]) })


   buf:setText(
   row,
   pRange[1] - 1,
   row,
   pRange[2],
   { line:sub(cRange[1], cRange[2]) })


   local mode = nvim.api.getMode().mode
   local pos = { cursorPos[1], cRange[2] - (mode == "i" and 0 or 1) }
   win:setCursor(pos)
end)

map("n", "<leader>head", z.asyncFn(function()
   local buf = nvim.Buffer()
   local lines = buf:getLines(0, -1, false)
   if #lines ~= 1 or lines[1] ~= "" then
      nvim.api.errWriteln("Cannot insert header guard: Buffer is not empty")
      return
   end
   local guard = input.input({ prompt = "Insert Header Guard: " })
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
   local buf = nvim.Buffer()
   local lines = buf:getLines(0, -1, false)
   if #lines ~= 1 or lines[1] ~= "" then
      nvim.api.errWriteln("Cannot insert STB style guard: Buffer is not empty")
      return
   end
   local guard = input.input({ prompt = "Insert STB style guard: " })
   if not guard then return end

   local normalized = guard:upper():gsub("%s", "_")
   local header = normalized .. "_H"
   local impl = normalized .. "_IMPLEMENTATION"
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
   local function execBuffer(b)
      b = b or nvim.Buffer()
      local lines = b:getLines(0, -1, false)
      local txt = table.concat(lines, "\n")

      local chunk, loaderr = loadstring(txt)
      if not chunk then
         nvim.api.errWriteln(loaderr)
         return
      end
      local ok, err = pcall(chunk)
      if not ok then
         nvim.api.errWriteln(err)
      end
   end

   map("n", "<leader>L", execBuffer)
end

do

   local pathSeparator = package.config:sub(1, 1)
   local inputDialog, result
   local currentlyMatching = false
   local function init()
      if not inputDialog then
         inputDialog = dialog.new({
            row = .25,
            wid = .4, hei = 1,
            centered = { horizontal = true },
            ephemeral = true,
            interactive = true,
         })
      end
      if not result then
         local cfg = inputDialog:win():getConfig()
         local row = (cfg.row)[false] + cfg.height + 2
         result = dialog.new({
            row = row,
            wid = .4, hei = .2,
            centered = { horizontal = true },
            ephemeral = true,
         })
      end
   end
   local function close()
      currentlyMatching = false
      if inputDialog then inputDialog:close() end; inputDialog = nil
      if result then result:close() end; result = nil
   end

   local function ls(dirname)
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
      inputDialog:show()
      nvim.command([[startinsert]])

      result:win():setOption("cursorline", true)
      result:win():setOption("cursorlineopt", "line")

      local b = inputDialog:ensureBuf()
      inputDialog:setModifiable(true)

      local function currentInput()
         local ln = inputDialog:getLine(1)
         local head, tail = ln:match("(.*)" .. pathSeparator .. "([^" .. pathSeparator .. "]*)$")
         if not tail then
            return "", ln
         end
         return head, tail
      end

      local function currentDir()
         local components = {}
         for _, path in ipairs({ uv.cwd(), (currentInput()) }) do
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

      local function isDir(path)
         local stat = uv.fs_stat(path)
         return stat and stat.type == "directory"
      end

      b:setKeymap("i", "<c-n>", function()
         local win = result:win()
         local cursor = win:getCursor()
         cursor[1] = cursor[1] + 1
         pcall(function() win:setCursor(cursor) end)
      end, {})

      b:setKeymap("i", "<c-p>", function()
         local win = result:win()
         local cursor = win:getCursor()
         cursor[1] = cursor[1] - 1
         pcall(function() win:setCursor(cursor) end)
      end, {})

      local function setInput(ln)
         inputDialog:setLines({ ln })
         vim.schedule(function() inputDialog:setCursor(1, #ln) end)
      end

      b:setKeymap("i", "<c-y>", function()
         local new = currentInput()
         local compl = result:getCurrentLine()
         if #new > 0 then
            new = new .. pathSeparator
         end
         setInput(new .. compl .. pathSeparator)
      end, {})

      b:setKeymap("n", "<esc>", close, {})
      b:setKeymap("i", "<esc>", function() nvim.command("stopinsert"); close() end, {})
      b:setKeymap("i", "<cr>", function()
         local res = inputDialog:getLine(1)
         close()
         nvim.command("stopinsert")
         nvim.command("tcd %s", res)
         print("tcd: " .. res)
      end, {})

      local function updateResultText()
         local cd = currentDir()
         if currentlyMatching then
            local head, tail = currentInput()
            local matches = {}
            local patt = "^" .. vim.pesc(tail)
            for _, v in ipairs(ls(cd)) do
               if v:match(patt) and isDir((#head > 0 and head .. pathSeparator or "") .. v) then
                  table.insert(matches, v)
               end
            end
            if #matches == 1 then
               currentlyMatching = false
               vim.schedule(function()
                  local newLn = (#head > 0 and head .. pathSeparator or "") .. matches[1] .. pathSeparator
                  setInput(newLn)
               end)
            else
               vim.schedule(function()
                  result:setLines({
                     "ls: " .. cd .. (cd:match(pathSeparator .. "$") and "" or pathSeparator) .. "...",
                     ("-- %d Director%s matching %q --"):format(
                     #matches,
                     #matches == 1 and "y" or "ies",
                     tail),

                  })
                  result:appendLines(matches)
               end)
            end
         else
            local dirs, files = {}, {}
            for _, v in ipairs(ls(cd)) do
               table.insert(isDir(cd .. pathSeparator .. v) and dirs or files, v)
            end
            vim.schedule(function()
               result:setLines({
                  "ls: " .. cd,
                  ("-- %d Director%s --"):format(#dirs, #dirs == 1 and "y" or "ies"),
               })
               result:appendLines(dirs)
               result:appendLines({
                  ("-- %d File%s --"):format(#files, #files == 1 and "" or "s"),
               })
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