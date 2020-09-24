package.loaded["euclidian.config"] = nil

local a = vim.api
local cmd = a.nvim_command


local export = {
   mapping = setmetatable({}, {
      __index = function(self, index)
         rawset(self, index, {})
         return self[index]
      end,
   }),
   autocommands = {},
}

local function cmdf(command, ...)
   cmd(command:format(...))
end

local function partial(f, a)
   return function(...)
      return f(a, ...)
   end
end

local function trim(s)
   return (s:gsub("^%s*(.*)%s*$", "%1"))
end

local function fstsnd(arr)
   local i = 0
   return function()
      i = i + 1
      if not arr[i] then
         return
      end
      return arr[i][1], arr[i][2]
   end
end


local settings = { noremap = true, silent = true }
local function map(mode, lhs, rhs, user_settings)
   local user_settings = user_settings or settings
   if type(rhs) == "string" then
      a.nvim_set_keymap(mode, lhs, rhs, user_settings)
   elseif type(rhs) == "function" then

      local correct_lhs = lhs:gsub("<leader>", a.nvim_get_var("mapleader"))
      export.mapping[mode][correct_lhs] = partial(pcall, rhs)
      a.nvim_set_keymap(
mode,
lhs,
string.format(":lua require('euclidian.config').mapping[%q][%q]()<CR>", mode, lhs),
user_settings)

   end
end

local function unmap(mode, lhs)
   local correct_lhs = lhs:gsub("<leader>", a.nvim_get_var("mapleader"))
   pcall(a.nvim_del_keymap, mode, correct_lhs)
end










local lsp = require("nvim_lsp")
local lspSettings = {

   sumneko_lua = { settings = { Lua = {
            runtime = { version = "Lua 5.3" },
            diagnostics = {
               globals = {

                  "vim",


                  "tup",


                  "it", "describe", "setup", "teardown", "pending", "finally",


                  "turtle", "fs", "shell",


                  "awesome", "screen", "mouse", "client", "root",
               },
               disable = {
                  "empty-block",
                  "undefined-global",
                  "unused-function",
               },
            },
         }, }, },

   clangd = {},
}

for server, settings in pairs(lspSettings) do
   lsp[server].setup(settings)
end


local stl = require("euclidian.statusline")

stl.mode("ic", "Insert-C", "DraculaGreenBold")
stl.mode("ix", "Insert-X", "DraculaGreenBold")
stl.mode("R", "Replace", "DraculaRed")
stl.mode("t", "Terminal", "DraculaOrange")

stl.add({ "LeadingSpace", "Spaces", "Active", "Inactive" }, {}, " ", "Comment")
stl.add({ "ModeText", "Active" }, { "Inactive" }, function()
   return "[" .. stl.getModeText() .. "]"
end, "StatuslineModeText")
stl.add({ "BufferNumber", "Active", "Inactive" }, { "Debugging" }, "[buf: %n]", "Comment")
stl.add({ "FileName", "Active", "Inactive" }, { "Debugging" }, "[%.30f]", "Identifier")
stl.add({ "GitBranch", "Active", "Inactive" }, { "Debugging" }, function()

   local branch = (vim.fn.FugitiveStatusline()):sub(6, -3)
   if branch == "" then
      return ""
   end
   return "[* " .. branch .. "]"
end, "DraculaGreen")
stl.add({ "EditInfo", "Active", "Inactive" }, { "Debugging" }, "%y%r%h%w%m ", "Comment")
stl.add({ "SyntaxViewer", "Debugging" }, { "Inactive" }, function()
   local cursor = a.nvim_win_get_cursor(0)
   return "[Syntax: " .. vim.fn.synIDattr(vim.fn.synID(cursor[1], cursor[2] + 1, 0), "name") .. "]"
end, "DraculaOrangeBold")
stl.add({ "IndentViewer", "Debugging" }, { "Inactive" }, function()
   local indentexpr
   do
      local ok
      ok, indentexpr = pcall(a.nvim_buf_get_option, 0, "indentexpr")
      if not ok or not indentexpr then
         return ""
      end
   end
   local shiftwidth = a.nvim_buf_get_option(0, "shiftwidth")
   if not shiftwidth then
      shiftwidth = 1
   end
   local cursor = a.nvim_win_get_cursor(0)
   local indent
   do
      local ok
      ok, indent = pcall(vim.fn[indentexpr:gsub("%(.*$", "")], tostring(cursor[1]))
      if not ok or not indent then
         return ""
      end
   end
   return ("[Indent: %d]"):format(indent / shiftwidth)
end, "DraculaGreenBold")
stl.add({ "ActiveSeparator", "Active" }, { "Inactive" }, "%=", "User1")
stl.add({ "InactiveSeparator", "Inactive" }, { "Active" }, "%=", "User2")
stl.add({ "Shiftwidth", "Tabstop", "Expandtab", "Active" }, { "Inactive" }, function()
   local sw = a.nvim_buf_get_option(0, "shiftwidth")
   local ts = a.nvim_buf_get_option(0, "tabstop")
   local expandtab = a.nvim_buf_get_option(0, "expandtab")
   return (" [sw:%d ts:%d expandtab:%s]"):format(sw, ts, expandtab and "yes" or "no")
end, "Identifier")
stl.add({ "LineNumber", "NavInfo", "Active", "Inactive" }, {}, " %l/%L:%c ", "Comment")
stl.add({ "FilePercent", "NavInfo", "Active", "Inactive" }, { "Debugging" }, "%3p%%", "Comment")
stl.add({ "TrailingSpace", "Spaces", "Active", "Inactive" }, {}, " ", "Comment")

cmd("hi! User1 guibg=#6F6F6F")
cmd("hi! User2 guibg=#1F1F1F")

map("n", "<F12>", function()    stl.toggleTag("Debugging") end)



local commenter = require("euclidian.commenter")
map("n", "<leader>c", function()
   local cursorPos = a.nvim_win_get_cursor(0)
   commenter.commentLine(0, cursorPos[1])
end)
map("v", "<leader>c", function()
   local start = (a.nvim_buf_get_mark(0, "<"))[1]
   local finish = (a.nvim_buf_get_mark(0, ">"))[1]
   for i = start, finish do
      commenter.commentLine(0, i)
   end
end)


local append = require("euclidian.append")
map("n", "<leader>a,", partial(append.toCurrentLine, ","))
map("v", "<leader>a,", function()
   local start = (a.nvim_buf_get_mark(0, "<"))[1] - 1
   local finish = (a.nvim_buf_get_mark(0, ">"))[1]
   append.toRange(start, finish, ",")
end)


for mvkey, szkey in fstsnd({
      { "h", "<" },
      { "j", "+" },
      { "k", "-" },
      { "l", ">" }, }) do

   unmap("n", "<C-W>" .. mvkey)
   map("n", "<C-" .. mvkey .. ">", ":wincmd " .. mvkey .. "<CR>")
   map("n", "<M-" .. mvkey .. ">", "<C-w>3" .. szkey)
   map("n", "<C-w>" .. mvkey, ":echoerr 'stop that'<CR>")
end


local function foldVisualSelection(label)

   local start = (a.nvim_buf_get_mark(0, "<"))[1] - 1
   local finish = (a.nvim_buf_get_mark(0, ">"))[1] + 1
   local commentstring = a.nvim_buf_get_option(0, "commentstring")
   local lb, rb = "{", "}"
   a.nvim_buf_set_lines(0, start, start, true, { string.format(commentstring, " " .. lb:rep(3) .. (label and (" " .. label) or "") .. " ") })
   a.nvim_buf_set_lines(0, finish, finish, true, { string.format(commentstring, " " .. rb:rep(3)) })
   return start, finish
end
map("v", "<leader>f", foldVisualSelection)
map("v", "<leader>F", function()
   local label = vim.fn.input("Fold label: ")
   local _, finish = foldVisualSelection(label)
   a.nvim_win_set_cursor(0, { finish + 1, 1 })
end)


local function termFunc()
   local termCmd = vim.fn.input("Command to execute in terminal: ")
   if #trim(termCmd) == 0 then
      return
   end
   cmd("sp +term")
   local termWin = a.nvim_get_current_win()
   local termBuf = a.nvim_get_current_buf()
   local ok, job = pcall(a.nvim_buf_get_var, 0, "terminal_job_id")
   if not ok then
      print("Unable to get terminal job id\n")
      return
   end
   unmap("n", "<leader>t")
   unmap("n", "<leader>T")
   map("n", "<leader>t", function()
      local ok = pcall(vim.fn.chansend, job, termCmd .. "\n")
      if not ok then
         print("[<leader>t] Unable to send command to terminal, (" .. termCmd .. ")")
      end
   end)
   map("n", "<leader>T", function()
      pcall(a.nvim_win_close, termWin, true)
      unmap("n", "<leader>T")
      map("n", "<leader>t", termFunc)
   end)






   print(", [<leader>t execute '" .. termCmd .. "'] [<leader>T close]")
end

map("n", "<leader>t", termFunc)


map("n", "<leader>lp", function()
   local curBuf = vim.fn.bufnr()
   cmd("augroup luaprinter")
   cmd("autocmd BufWritePost <buffer=" .. curBuf .. "> lua require('euclidian.luaprinter').runBuffer(" .. curBuf .. ", 10000)")
   cmd("autocmd InsertLeave  <buffer=" .. curBuf .. "> lua require('euclidian.luaprinter').runBuffer(" .. curBuf .. ", 1500)")
   cmd("augroup END")
   print("[euclidian.luaprinter] Attached lua printer to buffer", curBuf)
end)



return export