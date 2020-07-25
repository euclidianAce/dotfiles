local a = vim.api


local export = {
   mapping = {},
}


local function map(mode, lhs, rhs)
   local settings = { noremap = true, silent = true }
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

stl.mode("n", "Normal", "DraculaPurple")
stl.mode("i", "Insert", "DraculaGreen")
stl.mode("ic", "Insert-C", "DraculaGreenBold")
stl.mode("ix", "Insert-X", "DraculaGreenBold")
stl.mode("R", "Replace", "DraculaRed")
stl.mode("v", "Visual", "DraculaYellow")
stl.mode("V", "Visual Line", "DraculaYellow")
stl.mode("", "Visual Block", "DraculaYellow")
stl.mode("c", "Command", "DraculaPink")
stl.mode("s", "Select", "DraculaYellow")
stl.mode("S", "Select Line", "DraculaYellow")
stl.mode("", "Select Block", "DraculaYellow")
stl.mode("t", "Terminal", "DraculaOrange")
stl.mode("!", "Shell...", "Comment")

stl.add({ "LeadingSpace", "Spaces", "Active", "Inactive" }, {}, " ", "Comment")
stl.add({ "ModeText", "Active" }, { "Inactive" }, [=[[%{luaeval("require'statusline'.getModeText()")}]]=], "User3")
stl.add({ "BufferNumber", "Active", "Inactive" }, { "Debugging" }, "[buf: %n]", "Comment")
stl.add({ "FileName", "Active", "Inactive" }, { "Debugging" }, "[%.30f]", "Identifier")
stl.add({ "EditInfo", "Active", "Inactive" }, { "Debugging" }, "%y%r%h%w%m ", "Comment")
stl.add({ "SyntaxViewer", "Debugging" }, { "Inactive" }, [[ [%{synIDattr(synID(line("."), col("."), 0), "name")}]  ]], "DraculaPurpleBold")

stl.add({ "ActiveSeparator", "Active" }, { "Inactive" }, "%=", "User1")
stl.add({ "InactiveSeparator", "Inactive" }, { "Active" }, "%=", "User2")
stl.add({ "LineNumber", "NavInfo", "Active", "Inactive" }, {}, " %l/%L:%c ", "Comment")
stl.add({ "FilePercent", "NavInfo", "Active", "Inactive" }, { "Debugging" }, "%3p%%", "Comment")
stl.add({ "TrailingSpace", "Spaces", "Active", "Inactive" }, {}, " ", "Comment")

cmd("hi! User2 guibg=#1F1F1F")
cmd("hi! link User1 Visual")

map("n", "<F12>", function()    stl.toggleTag('Debugging') end)




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


return export
