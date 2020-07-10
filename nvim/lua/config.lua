
-- {{{ LSP
local lsp = require("nvim_lsp")
lsp.sumneko_lua.setup{
	settings = {
		Lua = {
			runtime = { version = "Lua 5.3" },
			diagnostics = {
				globals = {
					-- Vim api
					"vim",

					-- Tupfile.lua
					"tup",

					-- Busted
					"it",
					"describe",
					"setup",
					"teardown",
					"pending",
					"finally",
				}
			}
		}
	}
}
lsp.clangd.setup{}
-- }}}
