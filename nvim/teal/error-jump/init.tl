local record Target
	file: string
	line: integer
	column: integer
end

local record Found
	buffer: integer
	line_number: integer
	start_column: integer
	end_column: integer
end

-- Takes the line and cursor index into that line
-- Returns the inclusive range of the found target and the target
local type Matcher = function(string, integer): integer, integer, Target

-- matches things like
--
-- foo.c:1
-- foo.c:1:2
local function match_unixy(line: string, cursor_index: integer): integer, integer, Target
	for start_, file, line_index, finish_ in line:gmatch("()([^%s:]+):(%d+)()") do
		local start <const> = start_ as integer
		local finish = finish_ as integer - 1

		local rest <const> = line:sub(finish + 1, -1)
		local column_str <const> = rest:match("^:(%d+)")
		if column_str then
			finish = finish + #column_str
		end

		if start <= cursor_index and cursor_index <= finish then
			return start, finish, { file = file, line = tonumber(line_index) as integer, column = tonumber(column_str) as integer }
		end
	end
end

-- matches things like
--
-- foo.c(1)
-- foo.c(1,2)
local function match_windowsy(line: string, cursor_index: integer): integer, integer, Target
	for start_, file, in_parens, finish_ in line:gmatch("()([^%s()]+)%(([^()]+)%)()") do
		local start <const> = start_ as integer
		local finish = finish_ as integer - 1

		local line_index, column = in_parens:match("^%s*(%d+)%s*,%s*(%d+)%s*$")
		if not line_index then
			line_index = in_parens:match("^%s*(%d+)%s*$")
		end

		if start <= cursor_index and cursor_index <= finish then
			return start, finish, { file = file, line = tonumber(line_index) as integer, column = tonumber(column) as integer }
		end
	end
end

local matchers <const>: {Matcher} = {
	match_unixy,
	match_windowsy,
}

-- returns line index, found target
local function find_pattern_on_cursor(line: string, cursor_index: integer): integer, integer, Target
	for _, match in ipairs(matchers) do
		local a, b, c = match(line, cursor_index)
		if a then
			return a, b, c
		end
	end
end

global unpack: function<T>({T}): T...

local function under_cursor(window?: integer): Found, Target
	window = window or 0
	local line_number <const>, column_zero_index <const> = unpack(vim.api.nvim_win_get_cursor(window))
	local buf <const> = vim.api.nvim_win_get_buf(window)
	local line <const> = vim.api.nvim_buf_get_lines(buf, line_number - 1, line_number, false)[1]
	local start_index <const>, end_index <const>, target <const> = find_pattern_on_cursor(line, column_zero_index + 1)
	if start_index then
		return {
			buffer = buf,
			line_number = line_number,
			start_column = start_index,
			end_column = end_index,
		}, target
	end
end

local function on_key_wrapper(handler: function(Found, Target)): function()
	return function()
		local found <const>, target <const> = under_cursor(0)
		if found then handler(found, target) end
	end
end

local ns <const> = vim.api.nvim_create_namespace("")

local function default_handler(found: Found, target: Target)
	vim.cmd "normal m'"
	vim.highlight.range(
		found.buffer,
		ns,
		"Search",
		{ found.line_number - 1, found.start_column - 1 },
		{ found.line_number - 1, found.end_column + 1 },
		{}
	)
	vim.defer_fn(function() vim.api.nvim_buf_clear_namespace(found.buffer, ns, 0, -1) end, 350)

	vim.cmd("keepjumps drop " .. target.file)
	if target.line then
		local c <const> = (target.column or 1) - 1
		vim.api.nvim_win_set_cursor(0, { target.line, c })
		vim.cmd "normal m'"
	end

	local msg <const> = { ("Jumped to file ‘%s’"):format(target.file) }
	if target.line then
		table.insert(msg, ", line " .. tostring(target.line))
	end
	if target.column then
		table.insert(msg, ", column " .. tostring(target.column))
	end
	vim.notify(table.concat(msg), vim.log.levels.INFO, {})
end

return {
	on_key_wrapper = on_key_wrapper,
	default_handler = default_handler,
	under_cursor = under_cursor,
	Found = Found,
	Target = Target,
}
