
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




local function unpacker(arr)
   local i = 0
   return function()
      i = i + 1
      if not arr[i] then          return end
      return unpack(arr[i])
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


local dracula = {
   background = "#282a36",
   currentLine = "#44475a",
   foreground = "#f8f8f2",
   comment = "#6272a4",
   cyan = "#8be9fd",
   green = "#50fa7b",
   orange = "#ffb86c",
   pink = "#ff79c6",
   purple = "#bd93f9",
   red = "#ff5555",
   yellow = "#f1fa8c",
}
local stl = require("euclidian.statusline")
local stlHiGroup = "mySTL"
local function addHiGroup(name, fg, bg)
   cmd(
"hi def " .. name ..
   " guifg=" .. fg ..
   " guibg=" .. bg)

end
for mode, text, fg, bg in unpacker({
      { "n", "Normal", dracula.background, dracula.cyan },
      { "i", "Insert", dracula.background, dracula.green },
      { "ic", "Insert-Completion", dracula.background, dracula.green },
      { "c", "Command", dracula.background, dracula.pink },
      { "R", "Replace", dracula.background, dracula.red },
      { "t", "Terminal", dracula.background, dracula.orange },
      { "v", "Visual", dracula.background, dracula.yellow },
      { "V", "Visual Line", dracula.background, dracula.yellow },
      { "", "Visual Block", dracula.background, dracula.yellow },
   }) do
   addHiGroup(stlHiGroup .. mode, fg, bg)
   stl.mode(mode, text, stlHiGroup .. mode)
end

for hiGroupName, fg, bg in unpacker({
      { "CommentInverted", dracula.background, dracula.comment },
      { "TextInverted", dracula.background, dracula.foreground },
      { "GreenInverted", dracula.background, dracula.green },
      { "BrightGrayBg", dracula.background, "#6F6F6F" },
      { "DarkGrayBg", dracula.background, "#1F1F1F" },
      { "GitGreen", dracula.background, "#34d058" },
   }) do
   addHiGroup(hiGroupName, fg, bg)
end

stl.add({ "LeadingSpace", "Spaces", "Active", "Inactive" }, {}, " ", "CommentInverted")
stl.add({ "BufferNumber", "Active", "Inactive" }, { "Debugging" }, "%n ", "CommentInverted")
stl.add({ "ModeText", "Active" }, { "Inactive" }, function()
   return " " .. stl.getModeText() .. " "
end, "StatuslineModeText")
stl.add({ "GitBranch", "Active", "Inactive" }, { "Debugging" }, function()

   local branch = (vim.fn.FugitiveStatusline()):sub(6, -3)
   if branch == "" then
      return ""
   end
   return "  * " .. branch .. " "
end, "GitGreen")
stl.add({ "FileName", "Active", "Inactive" }, { "Debugging" },
function(winId)
   local ok, buf = pcall(a.nvim_win_get_buf, winId)
   if ok and buf then
      local fname = a.nvim_buf_get_name(buf)
      if fname:match("/bin/bash$") then
         return ""
      end
      if #fname > 15 then
         return "  <" .. fname:sub(-15, -1)
      end
      return "  " .. fname
   end
   return " ??? "
end, "BrightGrayBg")
stl.add({ "EditInfo", "Inactive" }, { "Debugging", "Active" }, "%m ", "BrightGrayBg")
stl.add({ "EditInfo", "Active" }, { "Debugging", "Inactive" }, "%m", "BrightGrayBg")
stl.add({ "EditInfo", "Active" }, { "Debugging", "Inactive" }, "%r%h%w", "BrightGrayBg")

stl.add({ "SyntaxViewer", "Treesitter", "Debugging" }, { "Inactive" }, function()
   return "[TS: " .. vim.fn["nvim_treesitter#statusline"](90) .. "]"
end, "DraculaGreen")
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

stl.add({ "ActiveSeparator", "Active" }, { "Inactive" }, "%=", "BrightGrayBg")
stl.add({ "InactiveSeparator", "Inactive" }, { "Active" }, "%=", "DarkGrayBg")
stl.add({ "Shiftwidth", "Tabstop", "Expandtab", "Active" }, { "Inactive" }, function()
   local expandtab = a.nvim_buf_get_option(0, "expandtab")
   local num
   if expandtab == 1 then
      num = a.nvim_buf_get_option(0, "tabstop")
   else
      num = a.nvim_buf_get_option(0, "shiftwidth")
   end
   return ("  %s (%d) "):format(expandtab and "spaces" or "tabs", num)
end, "BrightGrayBg")
stl.add({ "LineNumber", "NavInfo", "Active", "Inactive" }, {}, " %l/%L:%c ", "CommentInverted")
stl.add({ "FilePercent", "NavInfo", "Active", "Inactive" }, { "Debugging" }, "%3p%%", "CommentInverted")
stl.add({ "TrailingSpace", "Spaces", "Active", "Inactive" }, {}, " ", "CommentInverted")

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


for mvkey, szkey in unpacker({
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
   local fname = a.nvim_buf_get_name(0)
   print("[euclidian.luaprinter] Attached lua printer to buffer", curBuf, "(", fname, ")")
end)



return export