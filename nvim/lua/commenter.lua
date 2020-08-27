local a = vim.api

local M = {}

local function escapeStr(str)
   return (str:gsub("[-+.*()%[%]]", "%%%1"))
end

function M.commentStr(cs, str)
   local escc = escapeStr(cs)
   local patt = escc:gsub("%%s", "(.*)")
   local leadingWhitespace, line = str:match("(%s*)(.*)")
   return leadingWhitespace .. (line:match(patt) or (cs:gsub("%%s", line)))
end

function M.commentLine(buf, lineNum)
   local c = a.nvim_buf_get_option(buf, "commentstring")
   if not c then
      print("Couldn't get commentstring")
      return
   end
   a.nvim_buf_set_lines(buf, lineNum - 1, lineNum, false, {
      M.commentStr(c, a.nvim_buf_get_lines(buf, lineNum - 1, lineNum, false)[1]),
   })
end

return M
