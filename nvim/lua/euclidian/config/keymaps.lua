local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
local z = require("euclidian.lib.azync")
local a = vim.api
local uv = vim.loop

local function combinations(xs, ys)
   return coroutine.wrap(function()
      for _, x in ipairs(xs) do
         for _, y in ipairs(ys) do
            coroutine.yield(x, y)
         end
      end
   end)
end

local function ensureArray(t)

   if type(t) ~= "table" then
      return { t }
   elseif t then
      return t
   else
      return {}
   end
end

local function map(m, lhs, rhs)
   for mode, l in combinations(ensureArray(m), ensureArray(lhs)) do
      nvim.setKeymap(mode, l, rhs, { noremap = true, silent = true })
   end
end
local unmap = nvim.delKeymap








map("n", "<leader>cc", function()
   require("euclidian.lib.commenter").commentLine(0, nvim.Window():getCursor()[1])
end)
local OperatorfuncMode = {}


local commenter = require("euclidian.lib.commenter")
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

local function asyncInput(opts)
   local result
   z.suspend(function(me)
      vim.ui.input(opts, function(i)
         result = i
         z.resume(me)
      end)
   end)
   return result
end

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
   vim.ui.input({ prompt = "Append Characters: " }, function(input)
      if input then
         append.toRange(open, close, input, b.id)
      end
   end)
end

__euclidian.appendToVisualSelection = function(multiple)
   local b = nvim.Buffer()
   local open = b:getMark("<")[1]
   local close = b:getMark(">")[1]
   if multiple then
      vim.ui.input({ prompt = "Append Characters: " }, function(input)
         if input then
            append.toRange(open, close, input, b.id)
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
   vim.ui.input({ prompt = "Append Characters:" }, function(input)
      if input then
         append.toCurrentLine(input)
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
   unmap("n", "<C-W>" .. mvkey)
   map("n", "<C-" .. mvkey .. ">", "<cmd>wincmd " .. mvkey .. "<CR>")
   map("n", "<M-" .. mvkey .. ">", "<C-w>3" .. szkey)
end

map("n", "<leader>k", function() vim.diagnostic.show_line_diagnostics({ focusable = false }) end)
map("n", "K", vim.lsp.buf.hover)
map("n", "<leader>N", vim.diagnostic.goto_next)
map("n", "<leader>P", vim.diagnostic.goto_prev)

map("n", "<leader>fz", function() require("telescope.builtin").find_files() end)
map("n", "<leader>g", function() require("telescope.builtin").live_grep() end)

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


   local mode = vim.api.nvim_get_mode().mode
   local pos = { cursorPos[1], cRange[2] - (mode == "i" and 0 or 1) }
   win:setCursor(pos)
end)

map("n", "<leader>head", z.asyncFn(function()
   local buf = nvim.Buffer()
   local lines = buf:getLines(0, -1, false)
   if #lines ~= 1 or lines[1] ~= "" then
      vim.api.nvim_err_writeln("Cannot insert header guard: Buffer is not empty")
      return
   end
   local guard = asyncInput({ prompt = "Insert Header Guard: " })
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

do
   local function execBuffer(b)
      b = b or nvim.Buffer()
      local lines = b:getLines(0, -1, false)
      local txt = table.concat(lines, "\n")

      local chunk, loaderr = loadstring(txt)
      if not chunk then
         a.nvim_err_writeln(loaderr)
         return
      end
      local ok, err = pcall(chunk)
      if not ok then
         a.nvim_err_writeln(err)
      end
   end

   map("n", "<leader>L", execBuffer)
end

do

   local pathSeparator = package.config:sub(1, 1)
   local input, result
   local currentlyMatching = false
   local function init()
      if not input then
         input = dialog.new({
            row = .25,
            wid = .4, hei = 1,
            centered = { horizontal = true },
            ephemeral = true,
            interactive = true,
         })
      end
      if not result then
         local cfg = input:win():getConfig()
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
      if input then input:close() end; input = nil
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
      input:show()
      nvim.command([[startinsert]])

      result:win():setOption("cursorline", true)
      result:win():setOption("cursorlineopt", "line")

      local b = input:ensureBuf()
      input:setModifiable(true)

      local function currentInput()
         local ln = input:getLine(1)
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
         input:setLines({ ln })
         vim.schedule(function() input:setCursor(1, #ln) end)
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
         local res = input:getLine(1)
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

do
   local floatterm = require("euclidian.plug.floatterm.api")
   local locationjump = require("euclidian.plug.locationjump.api")
   local function jumpcWORD()
      local expanded = vim.fn.expand("<cWORD>")

      local file, line = locationjump.parseLocation(expanded)
      if file then
         floatterm.hide()
         nvim.command("new")
         locationjump.jump(file, line)
      end
   end

   local function getLastVisualSelection(buf)
      local left = buf:getMark("<")
      local right = buf:getMark(">")
      local lines = buf:getLines(left[1] - 1, right[1], true)
      if #lines == 0 then
         return ""
      end
      lines[1] = lines[1]:sub(left[2], #lines[1])
      lines[#lines] = lines[#lines]:sub(1, right[2])
      return table.concat(lines, "\n")
   end

   __euclidian.jumpHighlighted = function()
      local buf = floatterm.buffer()
      local selection = getLastVisualSelection(buf)
      local results = locationjump.parseAllLocations(selection)
      if #results > 0 then
         floatterm.hide()
         nvim.command("new")
         locationjump.selectLocation(results)
      end
   end

   floatterm.buffer():setKeymap("n", "J", jumpcWORD, { noremap = true, silent = true })
   floatterm.buffer():setKeymap("v", "J", "<esc>:lua __euclidian.jumpHighlighted()<cr>", { noremap = true, silent = true })
end