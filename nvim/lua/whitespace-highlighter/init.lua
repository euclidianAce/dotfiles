local ns = vim.api.nvim_create_namespace("")

local function add_mark(bufnr, row, start, finish)

   vim.api.nvim_buf_set_extmark(bufnr, ns, row, start - 1, {
      ephemeral = true,
      end_line = row,
      end_col = finish,
      hl_group = "EuclidianTrailingWhitespace",
   })
end

local function check_line(bufnr, row, line, patt)
   local start, finish = line:match(patt)
   if start ~= finish then
      add_mark(bufnr, row, start, finish)
   end
end

local decoration_provider = {
   on_win = function(_, _winid, bufnr)
      local name = vim.api.nvim_buf_get_name(bufnr)
      if vim.startswith(name, "term://") then return false end
      local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
      if ft == "fugitive" then return false end
      return true
   end,
   on_line = function(_, _winid, bufnr, row)
      local ln = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]

      check_line(bufnr, row, ln, "()%s+()$")


      check_line(bufnr, row, ln, "() +\t*()\t")
      check_line(bufnr, row, ln, "()\t+ *() ")

      return true
   end,
}

local function enable()
   vim.api.nvim_set_decoration_provider(ns, decoration_provider)
end

local function disable()
   vim.api.nvim_set_decoration_provider(ns, {})
end

return {
   enable = enable,
   disable = disable,
}
