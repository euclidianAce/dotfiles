local pattern <const> = "([^%s]+):(%d+):(%d+)"

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

-- returns line index, found target
local function find_pattern_on_cursor(line: string, cursor_index: integer): integer, integer, Target
	for start_, file, line_index, column, finish in line:gmatch("()" .. pattern .. "()") do
		local start = start_ as integer
		if start <= cursor_index and cursor_index < finish as integer then
			return start, finish as integer, { file = file, line = tonumber(line_index) as integer, column = tonumber(column) as integer }
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
		{ found.line_number - 1, found.end_column - 1 },
		{}
	)
	vim.defer_fn(function() vim.api.nvim_buf_clear_namespace(found.buffer, ns, 0, -1) end, 350)

	vim.cmd("keepjumps drop " .. target.file)
	if target.line then
		local c <const> = (target.column or 1) - 1
		vim.api.nvim_win_set_cursor(0, { target.line, c })
		vim.cmd "normal m'"
	end
end

return {
	on_key_wrapper = on_key_wrapper,
	default_handler = default_handler,
	under_cursor = under_cursor,
	Found = Found,
	Target = Target,
}
