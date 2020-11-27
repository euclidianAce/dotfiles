
local a = vim.api
local cmd = a.nvim_command





function dump(...)
   for i = 1, select("#", ...) do
      print(vim.inspect((select(i, ...))))
   end
end

require("euclidian.config.colors")
require("euclidian.config.lsp")
require("euclidian.config.snippets")
require("euclidian.config.statusline")
require("euclidian.config.keymaps")

cmd([[autocmd Filetype lua  setlocal omnifunc=v:lua.vim.lsp.omnifunc]])
cmd([[autocmd Filetype [ch] setlocal omnifunc=v:lua.vim.lsp.omnifunc]])
