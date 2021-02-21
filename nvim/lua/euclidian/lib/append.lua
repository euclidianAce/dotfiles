
local nvim = require("euclidian.lib.nvim")

local append = {}

function append.toLine(lineNum, chars, bufid)
   local buf = nvim.Buffer(bufid)
   local len = #buf:getLines(lineNum - 1, lineNum, false)[1]
   buf:setText(lineNum - 1, len, lineNum - 1, len, { chars })
end

function append.toCurrentLine(chars, winid)
   local win = nvim.Window(winid)
   append.toLine(win:getCursor()[1], chars, win:getBuf())
end

function append.toRange(start, finish, chars, bufid)
   local buf = nvim.Buffer(bufid)
   local lines = buf:getLines(start, finish, false)
   for i, v in ipairs(lines) do
      lines[i] = v .. chars
   end
   buf:setLines(start, finish, false, lines)
end

return append