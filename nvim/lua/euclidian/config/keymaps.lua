
local M = { _exports = {} }

local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
local a = vim.api
local uv = vim.loop

local function combinations(as, bs)
   return coroutine.wrap(function()
      for _, x in ipairs(as) do
         for _, y in ipairs(bs) do
            coroutine.yield(x, y)
         end
      end
   end)
end

local function ensure_array(t)

   if type(t) ~= "table" then
      return { t }
   elseif t then
      return t
   else
      return {}
   end
end

local function map(m, lhs, rhs)
   for mode, l in combinations(ensure_array(m), ensure_array(lhs)) do
      nvim.setKeymap(mode, l, rhs, { noremap = true, silent = true })
   end
end
local function unmap(m, lhs)
   nvim.delKeymap(m, lhs)
end

local function bufMap(bufid, m, lhs, rhs)
   local buf = nvim.Buffer(bufid)
   for mode, l in combinations(ensure_array(m), ensure_array(lhs)) do
      buf:setKeymap(mode, l, rhs, { noremap = true, silent = true })
   end
end

map("n", "<leader>cc", function()
   local cursorPos = a.nvim_win_get_cursor(0)
   require("euclidian.lib.commenter").commentLine(0, cursorPos[1])
end)
local OperatorfuncMode = {}


local commenter = require("euclidian.lib.commenter")
M._exports.commentMotion = function(kind)
   if kind ~= "line" then return end
   local b = nvim.Buffer()
   commenter.commentRange(
   b.id,
   b:getMark('[')[1] - 1,
   b:getMark(']')[1])

end
M._exports.commentVisualSelection = function()
   local b = nvim.Buffer()
   commenter.commentRange(
   b.id,
   b:getMark('<')[1] - 1,
   b:getMark('>')[1])

end

map(
"n", "<leader>c",
[[<cmd>set opfunc=v:lua.euclidian.config.keymaps._exports.commentMotion")<cr>g@]])

map("v", "<leader>c", [[:lua require("euclidian.config.keymaps")._exports.commentVisualSelection()<cr>]])

local getchar = vim.fn.getchar
local append = require("euclidian.lib.append")

M._exports.appendMotion = function(kind)
   if kind ~= "line" then return end
   local b = nvim.Buffer()
   append.toRange(
   b:getMark('[')[1] - 1,
   b:getMark(']')[1],
   string.char(getchar()),
   b.id)

end
M._exports.appendToVisualSelection = function()
   local b = nvim.Buffer()
   append.toRange(
   b:getMark('<')[1] - 1,
   b:getMark('>')[1],
   string.char(getchar()),
   b.id)

end

map(
"n", "<leader>a",
[[<cmd>set opfunc=v:lua.euclidian.config.keymaps._exports.appendMotion")<cr>g@]])

map("n", "<leader>aa", function()
   append.toCurrentLine(string.char(getchar()))
end)
map("v", "<leader>a", [[:lua require("euclidian.config.keymaps")._exports.appendToVisualSelection()<cr>]])

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

map("n", "<leader>fz", require("telescope.builtin").find_files)
map("n", "<leader>g", require("telescope.builtin").live_grep)

map("n", "<leader>n", "<cmd>noh<cr>")

map("i", "{<CR>", "{}<Esc>i<CR><CR><Esc>kS")
map("i", "(<CR>", "()<Esc>i<CR><CR><Esc>kS")

map("t", "<Esc>", "<C-\\><C-n>")

do
   local d = dialog.new({
      wid = 75, hei = 30,
      centered = true,
      interactive = true,
      notMinimal = true,
      hidden = true,
   })
   d:setModifiable(true)

   local function configureBuf(buf)
      buf:setOption("ft", "teal")
      buf:setOption("tabstop", 3)
      buf:setOption("shiftwidth", 3)
      buf:setKeymap(
      "n", "<cr>",
      function()
         local lines = d:getLines()
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
      end,
      { silent = true, noremap = true })

      buf:setKeymap(
      "n", "",
      function() d:hide() end,
      { silent = true, noremap = true })

   end

   map("n", "<leader>lua", function()
      configureBuf(d:ensureBuf())
      d:show()
   end)
end

do
   local d = dialog.new({
      wid = 0.9, hei = 0.85,
      centered = true,
      interactive = true,
      hidden = true,
   })
   local buf = d:ensureBuf()

   local openTerm, hideTerm
   buf:setOption("modified", false)
   local bufOpenTerm = vim.schedule_wrap(function()
      vim.fn.termopen("bash")
   end)
   local key = ""

   M._exports.getTermChannel = function()
      return buf:getOption("channel")
   end
   M._exports.termSend = function(s)
      if not buf:isValid() then
         return false
      end
      a.nvim_chan_send(buf:getOption("channel"), s)
      return true
   end

   openTerm = function()
      if buf:getOption("buftype") ~= "terminal" then
         buf:call(bufOpenTerm)
      end
      d:show():win():setOption("winblend", 8)
   end

   hideTerm = function()
      d:hide()
      map("n", key, openTerm)
   end

   bufMap(buf.id, { "t", "n" }, key, hideTerm)
   map("n", key, openTerm)
end

do



   local input, result
   local currentlyMatching
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


map("n", "<S-Up>", function()
   local name, size = (a.nvim_get_option("guifont")):match("^(.*:h)(%d+)$")
   a.nvim_set_option("guifont", name .. tostring(tonumber(size) + 2))
end)
map("n", "<S-Down>", function()
   local name, size = (a.nvim_get_option("guifont")):match("^(.*:h)(%d+)$")
   a.nvim_set_option("guifont", name .. tostring(tonumber(size) - 2))
end)

return M