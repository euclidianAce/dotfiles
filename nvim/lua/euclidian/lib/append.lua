local nvim = require("euclidian.lib.nvim")

local append = {}

function append.toLine(lineNum, chars, bufid)
   local buf = nvim.Buffer(bufid)
   assert(buf:isValid(), "Invalid buffer")
   local len = #buf:getLines(lineNum - 1, lineNum, false)[1]
   buf:setText(lineNum - 1, len, lineNum - 1, len, { chars })
end

function append.toCurrentLine(chars, winid)
   local win = nvim.Window(winid)
   append.toLine(win:getCursor()[1], chars, win:getBuf())
end

function append.toRange(start, finish, chars, bufid)
   for ln = start, finish do
      append.toLine(ln, chars, bufid)
   end
end

function append.toLinesInMarks(mark1, mark2, chars, bufid)
   local buf = nvim.Buffer(bufid)
   append.toRange(buf:getMark(mark1)[1], buf:getMark(mark2)[1], chars, bufid)
end

function append.toLastVisualSelection(chars, bufid)
   append.toLinesInMarks("<", ">", chars, bufid)
end

function append.toLastYank(chars, bufid)
   append.toLinesInMarks("[", "]", chars, bufid)
end

return append