

local commenter = {}

local nvim = require("euclidian.lib.nvim")

local trim = vim.trim
local escapeStr = vim.pesc

local function split(str, delimiter)
   local found = str:find(delimiter, 1, true)
   if not found then
      return str, ""
   end
   return str:sub(1, found - 1), str:sub(found + #delimiter, -1)
end

local function getCommentString(buf)
   local c = nvim.Buffer(buf):getOption("commentstring")
   if not c then
      print("[commenter] Couldn't get commentstring")
      return
   end
   local pre, post = split(c, "%s")
   return trim(pre), trim(post)
end

local function isCommented(csPre, csPost, str)
   local commented = str:match("^%s*" .. escapeStr(csPre) .. " ?.-" .. escapeStr(csPost) .. "$")
   return commented ~= nil
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

   local b = nvim.Buffer(buf)
   b:setLines(lineNum - 1, lineNum, false, {
      commentStr(pre, post, b:getLines(lineNum - 1, lineNum, false)[1]),
   })
end

local function xor(a, b)
   return (not a and b) or (a and not b)
end

function commenter.commentRange(buf, start, finish)
   assert(buf, "no buffer")
   assert(start, "no start")
   assert(finish, "no finish")
   local b = nvim.Buffer(buf)
   local lines = b:getLines(start, finish, false)
   if not lines[1] then
      return
   end
   local pre, post = getCommentString(buf)
   local shouldBeCommented = not isCommented(pre, post, lines[1])

   lines[1] = commentStr(pre, post, lines[1])
   for i = 2, #lines do
      if xor(shouldBeCommented, isCommented(pre, post, lines[i])) then
         lines[i] = commentStr(pre, post, lines[i])
      end
   end
   b:setLines(start, finish, false, lines)
end

return commenter