local nvim <const> = require("euclidian.lib.nvim")

local append <const> = {}

function append.toLine(lineNum: integer, chars: string, bufid: integer)
	local buf <const> = nvim.Buffer(bufid)
	assert(buf:isValid(), "Invalid buffer")
	local len <const> = #buf:getLines(lineNum - 1, lineNum, false)[1]
	buf:setText(lineNum - 1, len, lineNum - 1, len, {chars})
end

function append.toCurrentLine(chars: string, winid: integer)
	local win <const> = nvim.Window(winid)
	append.toLine(win:getCursor()[1], chars, win:getBuf())
end

function append.toRange(start: integer, finish: integer, chars: string, bufid: integer)
	for ln = start, finish do
		append.toLine(ln, chars, bufid)
	end
end

function append.toLinesInMarks(mark1: string, mark2: string, chars: string, bufid: integer)
	local buf <const> = nvim.Buffer(bufid)
	append.toRange(buf:getMark(mark1)[1], buf:getMark(mark2)[1], chars, bufid)
end

function append.toLastVisualSelection(chars: string, bufid: integer)
	append.toLinesInMarks("<", ">", chars, bufid)
end

function append.toLastYank(chars: string, bufid: integer)
	append.toLinesInMarks("[", "]", chars, bufid)
end

return append
