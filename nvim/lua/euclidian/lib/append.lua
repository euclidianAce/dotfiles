local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs
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