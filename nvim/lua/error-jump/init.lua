local Target = {}





local Found = {}










local error_jump = {
   Target = Target,
   Found = Found,
   Matcher = Matcher,
   matchers = {},
}





function error_jump.match_unixy(line, cursor_index)
   for start_, file, line_index, finish_ in line:gmatch("()([^%s:]+):(%d+)()") do
      local start = start_
      local finish_inclusive = finish_ - 1

      local rest = line:sub(finish_inclusive + 1, -1)
      local column_str = rest:match("^:(%d+)")
      if column_str then
         local n = #column_str + 1
         finish_inclusive = finish_inclusive + n
         if rest:sub(n + 1, n + 1) == ":" then
            finish_inclusive = finish_inclusive + 1
         end
      end

      if start <= cursor_index and cursor_index <= finish_inclusive then
         return start, finish_inclusive, {
            file = file,
            line = tonumber(line_index),
            column = tonumber(column_str),
         }
      end
   end
end

table.insert(error_jump.matchers, error_jump.match_unixy)





function error_jump.match_windowsy(line, cursor_index)
   for start_, file, in_parens, finish_ in line:gmatch("()([^%s()]+)%(([^()]+)%)()") do
      local start = start_
      local finish_inclusive = finish_ - 1

      local line_index, column = in_parens:match("^%s*(%d+)%s*,%s*(%d+)%s*$")
      if not line_index then
         line_index = in_parens:match("^%s*(%d+)%s*$")
      end

      if start <= cursor_index and cursor_index <= finish_inclusive then
         return start, finish_inclusive, {
            file = file,
            line = tonumber(line_index),
            column = tonumber(column),
         }
      end
   end
end

table.insert(error_jump.matchers, error_jump.match_windowsy)


local function find_pattern_on_cursor(line, cursor_index)
   for _, match in ipairs(error_jump.matchers) do
      local a, b, c = match(line, cursor_index)
      if a then
         return a, b, c
      end
   end
end



function error_jump.under_cursor(window)
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





function error_jump.on_key_wrapper(handler)
   return function()
      local found, target = error_jump.under_cursor(0)
      if found then handler(found, target) end
   end
end

local ns = vim.api.nvim_create_namespace("")

function error_jump.default_handler(found, target)
   vim.cmd("normal m'")
   vim.highlight.range(
   found.buffer,
   ns,
   "Search",
   { found.line_number - 1, found.start_column - 1 },
   { found.line_number - 1, found.end_column },
   {})

   vim.defer_fn(function() vim.api.nvim_buf_clear_namespace(found.buffer, ns, 0, -1) end, 350)

   vim.cmd("keepjumps drop " .. target.file)
   if target.line then
      local c = (target.column or 1) - 1
      vim.api.nvim_win_set_cursor(0, { target.line, c })
      vim.cmd("normal m'")
   end

   local msg = { ("Jumped to file ‘%s’"):format(target.file) }
   if target.line then
      table.insert(msg, ", line " .. tostring(target.line))
   end
   if target.column then
      table.insert(msg, ", column " .. tostring(target.column))
   end
   vim.notify(table.concat(msg), vim.log.levels.INFO, {})
end

return error_jump
