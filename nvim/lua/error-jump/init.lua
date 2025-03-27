local pattern = "([^%s]+):(%d+):(%d+)"


local function find_pattern_on_cursor(line, cursor_index)
   for start_, file, line_index, column, finish in line:gmatch("()" .. pattern .. "()") do
      local start = start_
      if start <= cursor_index and cursor_index < finish then
         return start, file, tonumber(line_index), tonumber(column)
      end
   end
end



local function under_cursor(window)
   local line_number, column_zero_index = unpack(vim.api.nvim_win_get_cursor(window or 0))
   local line = vim.api.nvim_buf_get_lines(0, line_number - 1, line_number, false)[1]
   return find_pattern_on_cursor(line, column_zero_index + 1)
end

local function on_key_wrapper(handler)
   return function()
      local found_index, file, file_line, file_column = under_cursor(0)
      if found_index then handler(file, file_line, file_column) end
   end
end

local function default_handler(file, line, column)
   vim.cmd("normal m'")
   local cmd = "keepjumps drop " .. file
   vim.cmd(cmd)
   if line then
      local c = (column or 1) - 1
      vim.api.nvim_win_set_cursor(0, { line, c })
      vim.cmd("normal m'")
   end
end

return {
   on_key_wrapper = on_key_wrapper,
   default_handler = default_handler,
   under_cursor = under_cursor,
}
