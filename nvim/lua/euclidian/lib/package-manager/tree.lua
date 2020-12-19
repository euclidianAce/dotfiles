
local dataPath = vim.fn.stdpath("data")
local tree = {
   neovim = dataPath .. "/site/pack/package-manager/opt",
   luarocks = dataPath .. "/site/pack/package-manager/luarocks",
}

return tree
