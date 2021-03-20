local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table
local M = { _exports = {} }

local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
local a = vim.api

local function map(m, lhs, rhs)
   if type(m) == "string" then
      nvim.setKeymap(m, lhs, rhs, { noremap = true, silent = true })
   else
      for _, mode in ipairs(m) do
         nvim.setKeymap(mode, lhs, rhs, { noremap = true, silent = true })
      end
   end
end
local function unmap(m, lhs)
   nvim.delKeymap(m, lhs)
end

local function bufMap(bufid, m, lhs, rhs)
   local buf = nvim.Buffer(bufid)
   if type(m) == "string" then
      buf:setKeymap(m, lhs, rhs, { noremap = true, silent = true })
   else
      for _, mode in ipairs(m) do
         buf:setKeymap(mode, lhs, rhs, { noremap = true, silent = true })
      end
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
   local d
   local buf

   map("n", "<leader>lua", function()
      d = dialog.centered(75, 30, buf)
      if not buf then
         buf = d.buf
         buf:setOption("ft", "teal")
         buf:setOption("tabstop", 3)
         buf:setOption("shiftwidth", 3)
         buf:setKeymap(
         "n", "<cr>",
         function() M._exports.luaPrompt() end,
         { silent = true, noremap = true })

         buf:setKeymap(
         "n", "",
         function() d.win:hide() end,
         { silent = true, noremap = true })

      end
      d:setModifiable(true)
      M._exports.luaPrompt = function()
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
      end
   end)
end

do
   local fBuf, fWin
   local openTerm, hideTerm

   M._exports.getTermChannel = function()
      return fBuf and fBuf:getOption("channel")
   end
   M._exports.termSend = function(s)
      if not fBuf or not fBuf:isValid() then
         return false
      end
      vim.fn.chansend(fBuf:getOption("channel"), s)
      return true
   end

   local function incBlend()
      fWin:setOption("winblend", fWin:getOption("winblend") - 8)
   end
   local function decBlend()
      fWin:setOption("winblend", fWin:getOption("winblend") + 8)
   end

   local key = ""

   openTerm = function()
      if fWin and fWin:isValid() then
         a.nvim_set_current_win(fWin.id)
      elseif not (fBuf and fBuf:isValid()) then
         fBuf = nvim.createBuf(true, false)
         local opts = 
         dialog.centeredSize(math.huge, math.huge)

         fWin = nvim.openWin(fBuf, true, {
            relative = "editor",
            row = opts.row, col = opts.col, width = opts.wid, height = opts.hei,
         })

         fWin:setOption("winblend", 16)



         fBuf:setOption("modified", false)

         nvim.command([[term]])
         bufMap(fBuf.id, { "t", "n" }, key, hideTerm)
         bufMap(fBuf.id, { "t", "n" }, "", decBlend)
         bufMap(fBuf.id, { "t", "n" }, "", incBlend)
      else
         local opts = 
         dialog.centeredSize(math.huge, math.huge)

         fWin = nvim.openWin(fBuf, true, {
            relative = "editor",
            row = opts.row, col = opts.col, width = opts.wid, height = opts.hei,
         })
      end
   end

   hideTerm = function()
      if fWin:isValid() then
         fWin:hide()
      end
      fWin = nil
      map("n", key, openTerm)
   end

   map("n", key, openTerm)
end

return M