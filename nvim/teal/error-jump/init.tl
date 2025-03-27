local pattern <const> = "([^%s]+):(%d+):(%d+)"

-- returns line index, file, file line, file column
local function find_pattern_on_cursor(line: string, cursor_index: integer): integer, string, integer, integer
	for start_, file, line_index, column, finish in line:gmatch("()" .. pattern .. "()") do
		local start = start_ as integer
		if start <= cursor_index and cursor_index < finish as integer then
			return start, file, tonumber(line_index) as integer, tonumber(column) as integer
		end
	end
end

global unpack: function<T>({T}): T...

local function under_cursor(window?: integer): integer, string, integer, integer
	local line_number <const>, column_zero_index <const> = unpack(vim.api.nvim_win_get_cursor(window or 0))
	local line <const> = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, false)[1]
	return find_pattern_on_cursor(line, column_zero_index + 1)
end

local function on_key_wrapper(handler: function(string, ?integer, ?integer)): function()
	return function()
		local found_index <const>, file <const>, file_line <const>, file_column <const> = under_cursor(0)
		if found_index then handler(file, file_line, file_column) end
	end
end

local function default_handler(file: string, line?: integer, column?: integer)
	local cmd <const> = "drop " .. file
	vim.cmd(cmd)
	if line then
		vim.api.nvim_win_set_cursor(0, { line, (column or 1) - 1 })
	end
end

return {
	on_key_wrapper = on_key_wrapper,
	default_handler = default_handler,
	under_cursor = under_cursor,
}
