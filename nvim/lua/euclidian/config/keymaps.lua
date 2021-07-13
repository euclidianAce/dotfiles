
local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
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

local function getchar()
   return string.char(vim.fn.getchar())
end
local function getchars()
   return vim.fn.input("Append Characters:")
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
   append.toRange(
   b:getMark("[")[1],
   b:getMark("]")[1],
   getchars(),
   b.id)

end

__euclidian.appendToVisualSelection = function(multiple)
   local b = nvim.Buffer()
   local inputfn = multiple and getchars or getchar
   append.toRange(
   b:getMark("<")[1],
   b:getMark(">")[1],
   inputfn(),
   b.id)

end




map("v", "<leader>a", [[:lua __euclidian.appendToVisualSelection(false)<cr>]])
map("v", "<leader>A", [[:lua __euclidian.appendToVisualSelection(true)<cr>]])

map("n", "<leader>a", [[<cmd>set opfunc=v:lua.__euclidian.appendCharMotion")<cr>g@]])
map("n", "<leader>A", [[<cmd>set opfunc=v:lua.__euclidian.appendCharsMotion")<cr>g@]])

map("n", "<leader>aa", function() append.toCurrentLine(getchar()) end)
map("n", "<leader>AA", function() append.toCurrentLine(getchars()) end)

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

map("n", "<leader>k", vim.lsp.diagnostic.show_line_diagnostics)
map("n", "K", vim.lsp.buf.hover)
map("n", "<leader>N", vim.lsp.diagnostic.goto_next)
map("n", "<leader>P", vim.lsp.diagnostic.goto_prev)

map("n", "<leader>fz", function() require("telescope.builtin").find_files() end)
map("n", "<leader>g", function() require("telescope.builtin").live_grep() end)

map("n", "<leader>n", "<cmd>noh<cr>")

map("i", "{<CR>", "{}<Esc>i<CR><CR><Esc>kS")
map("i", "(<CR>", "()<Esc>i<CR><CR><Esc>kS")

map("t", "<Esc>", "<C-\\><C-n>")

map("n", "<leader>head", function()
   local buf = nvim.Buffer()
   local lines = buf:getLines(0, -1, false)
   if #lines ~= 1 or lines[1] ~= "" then
      vim.api.nvim_err_writeln("Cannot insert header guard: Buffer is not empty")
      return
   end
   local guard = vim.fn.input("Insert Header Guard: ")
   guard = guard:upper()
   if not guard:match("_H$") then
      guard = guard .. "_H"
   end
   buf:setLines(0, -1, false, {
      "#ifndef " .. guard,
      "#define " .. guard,
      "",
      "#endif // " .. guard,
   })
end)

do
   local function execBuffer(b)
      b = b or nvim.Buffer()
      local lines = b:getLines(0, -1, false);
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

      local b = input:ensureBuf()
      input:setModifiable(true)

      local function currentInput()
         local ln = input:getLine(1)
         local head, tail = ln:match("(.*)/([^/]*)$")
         if not tail then
            return "", ln
         end
         return head, tail
      end

      local function currentDir()
         local components = {}
         for _, path in ipairs({ uv.cwd(), (currentInput()) }) do
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

      local function isDir(path)
         local stat = uv.fs_stat(path)
         return stat and stat.type == "directory"
      end

      b:setKeymap("n", "<esc>", close, {})
      b:setKeymap("i", "<esc>", function() nvim.command([[stopinsert]]); close() end, {})
      b:setKeymap("i", "<cr>", function()
         local res = input:getLine(1)
         close()
         nvim.command([[stopinsert]])
         nvim.command("cd " .. res)
         print("cd: " .. res)
      end, {})

      local function updateResultText()
         local cd = currentDir()
         if currentlyMatching then
            local head, tail = currentInput()
            local matches = {}
            local patt = "^" .. vim.pesc(tail)
            for _, v in ipairs(ls(cd)) do
               if v:match(patt) and isDir((#head > 0 and head .. "/" or "") .. v) then
                  table.insert(matches, v)
               end
            end
            if #matches == 1 then
               currentlyMatching = false
               vim.schedule(function()
                  local newLn = (#head > 0 and head .. "/" or "") .. matches[1] .. "/"
                  input:setLines({ newLn })
                  input:setCursor(1, #newLn)
               end)
            else
               vim.schedule(function()
                  result:setLines({
                     "ls: " .. cd .. (cd:match("/$") and "" or "/") .. "...",
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
               table.insert(isDir(cd .. "/" .. v) and dirs or files, v)
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


local function getGuiFontInfo()
   return (a.nvim_get_option("guifont")):match("^(.*:h)(%d+)$")
end
map("n", "<S-Up>", function()
   local name, size = getGuiFontInfo()
   a.nvim_set_option("guifont", name .. tostring(tonumber(size) + 2))
end)
map("n", "<S-Down>", function()
   local name, size = getGuiFontInfo()
   a.nvim_set_option("guifont", name .. tostring(tonumber(size) - 2))
end)