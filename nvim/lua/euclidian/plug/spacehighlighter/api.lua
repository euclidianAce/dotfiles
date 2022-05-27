local nvim = require("euclidian.lib.nvim")
local ns = nvim.api.createNamespace("euclidian.plug.spacehighlighter")

local function enable(group)
   group = group or "TrailingWhitespace"
   nvim.api.setDecorationProvider(ns, {
      on_start = nil,
      on_buf = nil,
      on_win = function(_, _winid, bufnr)
         return not nvim.Buffer(bufnr):getName():match("^term://")
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
   nvim.api.setDecorationProvider(ns, {})
end

return {
   enable = enable,
   disable = disable,
}