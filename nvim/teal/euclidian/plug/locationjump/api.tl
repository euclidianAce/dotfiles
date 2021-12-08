local nvim <const> = require("euclidian.lib.nvim")

local locationjump <const> = {}

local pattern = "^(.*):(%d+)$"

function locationjump.setPattern(p: string)
	pattern = p
end

-- default format `filename:linenumber`
function locationjump.parseLocation(loc: string): string, integer
	assert(loc)
	local file, line = loc:match(pattern)
	return file, tonumber(line) as integer
end

function locationjump.jump(filename: string, line: integer)
	if line then
		nvim.command("edit +%d %s", line, filename)
	elseif filename then
		nvim.command("edit %s", filename)
	end
end

function locationjump.parseAndJump(loc: string)
	local file <const>, line <const> = locationjump.parseLocation(loc)
	if file and line then
		nvim.command("edit +%d %s", line, file)
	else
		vim.api.nvim_err_writeln("locationjump: Unable to parse file location from '" .. loc .. "'")
	end
end

function locationjump.jumpToVisualSelection()
	local buf <const> = nvim.Buffer()

	local a <const> = buf:getMark("<")
	local b <const> = buf:getMark(">")
	local lines = buf:getLines(a[1] - 1, b[1], true)
	if #lines ~= 1 then
		return
	end
	local text <const> = lines[1]:sub(a[2] + 1, b[2] + 1)
	locationjump.parseAndJump(text)
end

function locationjump.jumpExpand(expandArg: string)
	locationjump.parseAndJump(vim.fn.expand(expandArg) as string)
end

return locationjump
