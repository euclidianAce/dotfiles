local a = vim.api


local export = {
   mapping = {},
}


local settings = { noremap = true, silent = true }
local function map(mode, lhs, rhs)
   if type(rhs) == "string" then
      a.nvim_set_keymap(mode, lhs, rhs, settings)
   elseif type(rhs) == "function" then

      export.mapping[lhs:gsub("<leader>", a.nvim_get_var("mapleader"))] = rhs
      a.nvim_set_keymap(
mode,
lhs,
string.format(":lua require('config').mapping[%q]()<CR>", lhs),
settings)

   end
end

local cmd = a.nvim_command


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
















stl.add({ "LeadingSpace", "Spaces", "Active", "Inactive" }, {}, " ", "Comment")
stl.add({ "ModeText", "Active" }, { "Inactive" }, function()
   return "[" .. stl.getModeText() .. "]"
end, "StatuslineModeText")
stl.add({ "BufferNumber", "Active", "Inactive" }, { "Debugging" }, "[buf: %n]", "Comment")
stl.add({ "FileName", "Active", "Inactive" }, { "Debugging" }, "[%.30f]", "Identifier")
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
stl.add({ "Active" }, { "Inactive" }, function()
   local sw = a.nvim_buf_get_option(0, "shiftwidth")
   local ts = a.nvim_buf_get_option(0, "tabstop")
   return (" [sw:%d ts:%d]"):format(sw, ts)
end, "Identifier")
stl.add({ "LineNumber", "NavInfo", "Active", "Inactive" }, {}, " %l/%L:%c ", "Comment")
stl.add({ "FilePercent", "NavInfo", "Active", "Inactive" }, { "Debugging" }, "%3p%%", "Comment")
stl.add({ "TrailingSpace", "Spaces", "Active", "Inactive" }, {}, " ", "Comment")

cmd("hi! User2 guibg=#1F1F1F")
cmd("hi! link User1 Visual")

map("n", "<F12>", function()    stl.toggleTag("Debugging") end)




local function foldVisualSelection()
   local start = a.nvim_buf_get_mark(0, "<")[1] - 1
   local finish = a.nvim_buf_get_mark(0, ">")[1] + 1
   local commentstring = a.nvim_buf_get_option(0, "commentstring")
   a.nvim_buf_set_lines(0, start, start, true, { string.format(commentstring, " {{{") })
   a.nvim_buf_set_lines(0, finish, finish, true, { string.format(commentstring, " }}}") })
   return start, finish
end
map("v", "<leader>f", foldVisualSelection)

map("v", "<leader>F", function()
   local start = foldVisualSelection()
   a.nvim_win_set_cursor(0, { start + 1, 1 })
   a.nvim_input("A ")
end)
map("v", "<leader>s", ":sort<CR>")


return export
