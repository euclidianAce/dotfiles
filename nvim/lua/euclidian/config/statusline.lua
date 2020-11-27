
local color = require("euclidian.lib.color")
local p = require("euclidian.config.colors")
local stl = require("euclidian.lib.statusline")
local unpacker = require("euclidian.lib.util").unpacker
local a = vim.api
local winOption = a.nvim_win_get_option

local hi = color.scheme.hi
hi.STLBufferInfo = { 0, hi.Comment[1] }
hi.STLGit = { 0, p.darkGreen }
hi.STLFname = { 0, p.gray }
hi.STLNormal = { 0, p.blue }
hi.STLInsert = { 0, p.green }
hi.STLCommand = { 0, p.purple }
hi.STLReplace = { 0, p.red }

for m, txt, hl in unpacker({
      { "n", "Normal", "STLNormal" },
      { "i", "Insert", "STLInsert" },
      { "c", "Command", "STLCommand" },
      { "r", "Replace", "STLReplace" },
   }) do
   stl.mode(m, txt, hl)
end

stl.add({ "BufferNumber", "Active", "Inactive" }, {}, function(winId)
   return (" "):rep(winOption(winId, "numberwidth") + winOption(winId, "foldcolumn") + 1)
end, "STLBufferInfo")
stl.add({ "BufferNumber", "Active", "Inactive" }, {}, "%n ", "STLBufferInfo")
stl.add({ "ModeText", "Active" }, { "Inactive" }, function()
   return " " .. stl.getModeText() .. " "
end, stl.higroup)
stl.add({ "GitBranch", "Active", "Inactive" }, { "Debugging" }, function()

   local branch = (vim.fn.FugitiveStatusline()):sub(6, -3)
   if branch == "" then
      return ""
   end
   return "  * " .. branch .. " "
end, "STLGit")
local maxFileNameLen = 20
stl.add({ "FileName", "Active", "Inactive" }, { "Debugging" }, function(winId)


   local ok, buf = pcall(a.nvim_win_get_buf, winId)
   if ok and buf then
      local fname = a.nvim_buf_get_name(buf)
      if fname:match("/bin/bash$") then
         return ""
      end
      if #fname > maxFileNameLen then
         return "  <" .. fname:sub(-maxFileNameLen, -1)
      end
      return "  " .. fname
   end
   return " ??? "
end, "STLFname")
stl.add({ "EditInfo", "Active", "inactive" }, { "Debugging" }, "%m", "STLFname")
stl.add({ "EditInfo", "Active" }, { "Debugging", "Inactive" }, "%r%h%w", "STLFname")

stl.add({ "ActiveSeparator", "Active" }, { "Inactive" }, " %= ", "StatusLineNC")
stl.add({ "InactiveSeparator", "Inactive" }, { "Active" }, " %= ", "StatusLine")
stl.add({ "Shiftwidth", "Tabstop", "Expandtab", "Active" }, { "Inactive" }, function()
   local expandtab = a.nvim_buf_get_option(0, "expandtab")
   local num
   if expandtab == 1 then
      num = a.nvim_buf_get_option(0, "tabstop")
   else
      num = a.nvim_buf_get_option(0, "shiftwidth")
   end
   return ("  %s (%d) "):format(expandtab and "spaces" or "tabs", num)
end, "STLBufferInfo")
stl.add({ "LineNumber", "NavInfo", "Active", "Inactive" }, {}, " %l/%L:%c ", "STLBufferInfo")
stl.add({ "FilePercent", "NavInfo", "Active", "Inactive" }, { "Debugging" }, "%3p%%", "STLBufferInfo")
stl.add({ "TrailingSpace", "Spaces", "Active", "Inactive" }, {}, " ", "STLBufferInfo")
