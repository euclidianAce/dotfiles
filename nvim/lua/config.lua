local a = vim.api
local cmd = a.nvim_command


local export = {
   mapping = {},
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
   return (s:gsub("%s*(.*)%s*", "%1"))
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
      export.mapping[correct_lhs] = partial(pcall, rhs)
      a.nvim_set_keymap(
mode,
lhs,
string.format(":lua require('config').mapping[%q]()<CR>", lhs),
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
            diagnostics = { globals = {

                  "vim",


                  "tup",


                  "it",
                  "describe",
                  "setup",
                  "teardown",
                  "pending",
                  "finally",


                  "turtle",
                  "fs",
                  "shell",
               }, },
         }, }, },

   clangd = {},
}

for server, settings in pairs(lspSettings) do
   lsp[server].setup(settings)
end


local stl = require("statusline")

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
stl.add({ "Shiftwidth", "Tabstop", "Active" }, { "Inactive" }, function()
   local sw = a.nvim_buf_get_option(0, "shiftwidth")
   local ts = a.nvim_buf_get_option(0, "tabstop")
   return (" [sw:%d ts:%d]"):format(sw, ts)
end, "Identifier")
stl.add({ "LineNumber", "NavInfo", "Active", "Inactive" }, {}, " %l/%L:%c ", "Comment")
stl.add({ "FilePercent", "NavInfo", "Active", "Inactive" }, { "Debugging" }, "%3p%%", "Comment")
stl.add({ "TrailingSpace", "Spaces", "Active", "Inactive" }, {}, " ", "Comment")

cmd("hi! User1 guibg=#6F6F6F")
cmd("hi! User2 guibg=#1F1F1F")

map("n", "<F12>", function()    stl.toggleTag("Debugging") end)



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
   local ok, res = pcall(a.nvim_buf_get_var, 0, "terminal_job_id")
   if not ok then
      print("Unable to get terminal job id\n")
      return
   end
   unmap("n", "<leader>t")
   unmap("n", "<leader>T")
   map("n", "<leader>t", function()
      pcall(vim.fn.chansend, res, termCmd .. "\n")
   end)
   map("n", "<leader>T", function()
      pcall(a.nvim_win_close, termWin, true)
      unmap("n", "<leader>T")
      map("n", "<leader>t", termFunc)
   end)
   print(" \n")
   print("Press <leader>t to execute '" .. termCmd .. "' \nPress <leader>T to close the terminal\n")
end

map("n", "<leader>t", termFunc)



return export
