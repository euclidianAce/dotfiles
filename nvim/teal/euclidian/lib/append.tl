
local nvim <const> = require("euclidian.lib.nvim")

local append <const> = {}

function append.toLine(lineNum: integer, chars: string, bufid: integer)
	local buf <const> = nvim.Buffer(bufid)
	local len <const> = #buf:getLines(lineNum - 1, lineNum, false)[1]
	buf:setText(lineNum - 1, len, lineNum - 1, len, {chars})
end

function append.toCurrentLine(chars: string, winid: integer)
	local win <const> = nvim.Window(winid)
	append.toLine(win:getCursor()[1], chars, win:getBuf())
end

function append.toRange(start: integer, finish: integer, chars: string, bufid: integer)
	local buf <const> = nvim.Buffer(bufid)
	local lines <const> = buf:getLines(start, finish, false)
	for i, v in ipairs(lines) do
		lines[i] = v .. chars
	end
	buf:setLines(start, finish, false, lines)
end

return append
