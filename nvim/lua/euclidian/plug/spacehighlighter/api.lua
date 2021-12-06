local nvim = require("euclidian.lib.nvim")
local ns = vim.api.nvim_create_namespace("euclidian.plug.spacehighlighter")

local function enable(group)
   group = group or "TrailingWhitespace"
   vim.api.nvim_set_decoration_provider(ns, {
      on_start = nil,
      on_buf = nil,
      on_win = function()
         return true
      end,
      on_line = function(_, _winid, bufnr, row)
         local buf = nvim.Buffer(bufnr)

         local ln = buf:getLines(row, row + 1, false)[1];
         local start, finish = ln:match("()%s+()$")
         if start ~= finish then
            buf:setExtmark(ns, row, start - 1, {
               ephemeral = true,
               end_line = row,
               end_col = finish,
               hl_group = group,
            })
         end

         return true
      end,
      on_end = nil,
   })
end

local function disable()
   vim.api.nvim_set_decoration_provider(ns, {})
end

return {
   enable = enable,
   disable = disable,
}