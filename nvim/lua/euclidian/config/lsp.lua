
local lsp = require("lspconfig")
local lspSettings = {
   sumneko_lua = { settings = { Lua = {
            runtime = { version = "Lua 5.4" },
            diagnostics = {
               globals = {

                  "vim",


                  "tup",


                  "it", "describe", "setup", "teardown", "pending", "finally",


                  "turtle", "fs", "shell",


                  "awesome", "screen", "mouse", "client", "root",
               },
               disable = {
                  "empty-block",
                  "undefined-global",
                  "unused-function",
               },
            },
         }, }, },
   clangd = {},
}

for server, settings in pairs(lspSettings) do
   lsp[server].setup(settings)
end
