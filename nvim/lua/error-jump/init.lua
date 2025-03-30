local pattern = "([^%s]+):(%d+):(%d+)"

local Target = {}





local Found = {}







local function find_pattern_on_cursor(line, cursor_index)
   for start_, file, line_index, column, finish in line:gmatch("()" .. pattern .. "()") do
      local start = start_
      if start <= cursor_index and cursor_index < finish then
         return start, finish, { file = file, line = tonumber(line_index), column = tonumber(column) }
      end
   end
end



local function under_cursor(window)
   window = window or 0
   local line_number, column_zero_index = unpack(vim.api.nvim_win_get_cursor(window))
   local buf = vim.api.nvim_win_get_buf(window)
   local line = vim.api.nvim_buf_get_lines(buf, line_number - 1, line_number, false)[1]
   local start_index, end_index, target = find_pattern_on_cursor(line, column_zero_index + 1)
   if start_index then
      return {
         buffer = buf,
         line_number = line_number,
         start_column = start_index,
         end_column = end_index,
      }, target
   end
end

local function on_key_wrapper(handler)
   return function()
      local found, target = under_cursor(0)
      if found then handler(found, target) end
   end
end

local ns = vim.api.nvim_create_namespace("")

local function default_handler(found, target)
   vim.cmd("normal m'")
   vim.highlight.range(
   found.buffer,
   ns,
   "Search",
   { found.line_number - 1, found.start_column - 1 },
   { found.line_number - 1, found.end_column - 1 },
   {})

   vim.defer_fn(function() vim.api.nvim_buf_clear_namespace(found.buffer, ns, 0, -1) end, 350)

   vim.cmd("keepjumps drop " .. target.file)
   if target.line then
      local c = (target.column or 1) - 1
      vim.api.nvim_win_set_cursor(0, { target.line, c })
      vim.cmd("normal m'")
   end
end

return {
   on_key_wrapper = on_key_wrapper,
   default_handler = default_handler,
   under_cursor = under_cursor,
   Found = Found,
   Target = Target,
}
