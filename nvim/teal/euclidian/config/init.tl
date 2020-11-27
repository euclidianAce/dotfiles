
local a = vim.api
local cmd = a.nvim_command

-- FIXME: Nov 19 01:51 2020
--        leaving out the type annotation is apparently valid here?
--        gives a message like got type 'whatever', expected '<unknown type>'

global function dump(...: any)
	for i = 1, select("#", ...) do
		print(vim.inspect((select(i, ...))))
	end
end

require("euclidian.config.colors")
require("euclidian.config.lsp")
require("euclidian.config.snippets")
require("euclidian.config.statusline")
require("euclidian.config.keymaps")

cmd [[autocmd Filetype lua  setlocal omnifunc=v:lua.vim.lsp.omnifunc]]
cmd [[autocmd Filetype [ch] setlocal omnifunc=v:lua.vim.lsp.omnifunc]]

