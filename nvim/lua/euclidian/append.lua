
local a = vim.api

local M = {}

function M.toLine(lineNum, chars, buf)
   buf = buf or 0
   local line = a.nvim_buf_get_lines(buf, lineNum - 1, lineNum, false)[1]
   a.nvim_buf_set_lines(buf, lineNum - 1, lineNum, false, { line .. chars })
end

function M.toCurrentLine(chars, buf)
   buf = buf or 0
   local cursorPos = a.nvim_win_get_cursor(buf)
   M.toLine(cursorPos[1], chars, buf)
end

function M.toRange(start, finish, chars, buf)
   buf = buf or 0
   local lines = a.nvim_buf_get_lines(buf, start, finish, false)
   for i, v in ipairs(lines) do
      lines[i] = v .. chars
   end
   a.nvim_buf_set_lines(buf, start, finish, false, lines)
end

return M