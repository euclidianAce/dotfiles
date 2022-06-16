local align <const> = {}

-- split according to a pattern, BUT don't discard the matched parts
local function chunks(source: string, pattern: string, raw: boolean): {string}
	local result <const> = {}
	local last = 1
	while true do
		local s, e = source:find(pattern, last, raw)
		if not e then
			table.insert(result, source:sub(last, -1))
			break
		end

		table.insert(result, source:sub(last, s - 1))
		table.insert(result, source:sub(s, e))
		last = e + 1
	end
	return result
end

local function pad(str: string, len: integer): string
	return str .. (" "):rep(len - #str)
end

function align.byPattern(lines: {string}, pattern: string, raw: boolean): {string}
	local resultbuf <const> = {}
	local longest = 0
	for i, line in ipairs(lines) do
		local parts <const> = chunks(line, pattern, raw)
		if longest < #parts then
			longest = #parts
		end
		resultbuf[i] = parts
	end

	for i = 1, longest do
		local len = 0
		for _, line in ipairs(resultbuf) do
			if line[i] and len < #line[i] then
				len = #line[i]
			end
		end

		for _, line in ipairs(resultbuf) do
			if line[i] and i ~= #line then
				line[i] = pad(line[i], len)
			end
		end
	end

	local result <const> = {}
	for i, line in ipairs(resultbuf) do
		result[i] = table.concat(line)
	end
	return result
end

return align
