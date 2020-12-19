
local dataPath <const> = vim.fn.stdpath("data") as string
local tree <const> = {
	neovim = dataPath .. "/site/pack/package-manager/opt",
	luarocks = dataPath .. "/site/pack/package-manager/luarocks",
}

return tree
