
local lsp = require("nvim_lsp")
lsp.sumneko_lua.setup{
	settings = {
		Lua = {
			runtime = { version = "Lua 5.4" }
		}
	}
}
lsp.clangd.setup{}
