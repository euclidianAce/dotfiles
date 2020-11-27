
local lsp = require("lspconfig")
local lspSettings = {
	sumneko_lua = { settings = { Lua = {
		runtime = { version = "Lua 5.4" },
		diagnostics = {
			globals = {
				-- Vim api
				"vim",

				-- Tupfile.lua
				"tup",

				-- Busted
				"it", "describe", "setup", "teardown", "pending", "finally",

				-- Computercraft
				"turtle", "fs", "shell",

				-- awesomewm
				"awesome", "screen", "mouse", "client", "root",
			},
			disable = {
				"empty-block",
				"undefined-global",
				"unused-function",
			},
		},
	} } },
	clangd = {},
}

for server, settings in pairs(lspSettings) do
	lsp[server].setup(settings)
end
