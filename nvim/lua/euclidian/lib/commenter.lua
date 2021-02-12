


local util = require("euclidian.lib.util")
local a = vim.api
local trim = util.str.trim

local commenter = {}

local escapeStr = vim.pesc

local function split(str, delimiter)
   local found = str:find(delimiter, 1, true)
   if not found then
      return str, ""
   end
   return str:sub(1, found - 1), str:sub(found + #delimiter, -1)
end

local function getCommentString(buf)
   local ok, c = pcall(a.nvim_buf_get_option, buf, "commentstring")
   if not (ok and c) then
      print("[commenter] Couldn't get commentstring")
      return
   end
   local pre, post = split(c, "%s")
   return trim(pre), trim(post)
end

local function isCommented(csPre, csPost, str)
   local commented = str:match("^%s*" .. escapeStr(csPre) .. " ?.-" .. escapeStr(csPost) .. "$")
   return commented
end

local function commentStr(pre, post, str)
   if trim(str) == "" then return str end
   local ws, m = str:match("^(%s*)" .. escapeStr(pre) .. " ?(.-)%s*" .. escapeStr(post) .. "$")


   if ws then
      return ws .. m
   end

   pre = trim(pre)
   post = trim(post)


   local leadingWs, rest = str:match("^(%s*)(.*)$")
   return leadingWs .. pre .. " " .. rest .. (#post > 0 and " " .. post or "")
end

function commenter.commentLine(buf, lineNum)
   local pre, post = getCommentString(buf)

   if not pre then
      return
   end
   a.nvim_buf_set_lines(buf, lineNum - 1, lineNum, false, {
      commentStr(pre, post, a.nvim_buf_get_lines(buf, lineNum - 1, lineNum, false)[1]),
   })
end

function commenter.commentRange(buf, start, finish)
   assert(buf, "no buffer")
   assert(start, "no start")
   assert(finish, "no finish")
   local lines = a.nvim_buf_get_lines(buf, start, finish, false)
   if not lines[1] then
      return
   end
   local pre, post = getCommentString(buf)
   local shouldBeCommented = not isCommented(pre, post, lines[1])

   lines[1] = commentStr(pre, post, lines[1])
   for i = 2, #lines do
      if util.xor(shouldBeCommented, isCommented(pre, post, lines[i])) then
         lines[i] = commentStr(pre, post, lines[i])
      end
   end
   a.nvim_buf_set_lines(buf, start, finish, false, lines)
end

return commenter