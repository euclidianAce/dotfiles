local nvim <const> = require("euclidian.lib.nvim")

local locationjump <const> = {}

local pattern = "([^%s:]+):(%d+)"

function locationjump.jump(filename: string, line: integer)
	if line then
		nvim.command("edit +%d %s", line, filename)
	elseif filename then
		nvim.command("edit %s", filename)
	end
end

function locationjump.selectLocation(locations: {{string, integer}})
	if #locations > 1 then
		vim.ui.select(locations, {
			prompt = "Multiple locations found:",
			format_item = function(item: {string, integer}): string
				if item[2] then
					return ("%s @ line %d"):format(item[1], item[2])
				end
				return ("%s"):format(item[1])
			end,
		}, function(item: {string, integer})
			if item then
				locationjump.jump(item[1], item[2])
			end
		end)
	else
		locationjump.jump(locations[1][1], locations[1][2])
	end
end

function locationjump.setPattern(p: string)
	pattern = p
end

function locationjump.parseAllLocations(str: string): {{string, integer}}
	local results <const> = {}
	for a, b in str:gmatch(pattern) do
		local n = tonumber(b) as integer
		table.insert(results, { a, n })
	end
	if #results == 0 then
		vim.api.nvim_err_writeln("locationjump: Unable to parse file location from '" .. str .. "'")
	end
	return results
end

-- default format `filename:linenumber`
function locationjump.parseLocation(loc: string): string, integer
	assert(loc)
	local file, line = loc:match("^" .. pattern .. "$")
	return file, tonumber(line) as integer
end

function locationjump.parseAndJump(text: string)
	local results <const> = locationjump.parseAllLocations(text)
	locationjump.selectLocation(results)
end

function locationjump.jumpToVisualSelection()
	local buf <const> = nvim.Buffer()

	local a <const> = buf:getMark("<")
	local b <const> = buf:getMark(">")
	local lines = buf:getLines(a[1] - 1, b[1], true)
	local text <const> = table.concat(lines, "\n")

	local results <const> = locationjump.parseAllLocations(text)
	locationjump.selectLocation(results)
end

function locationjump.jumpExpand(expandArg: string)
	locationjump.parseAndJump(vim.fn.expand(expandArg) as string)
end

return locationjump
