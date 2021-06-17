local fs <const> = require("euclidian.lib.fs")

local stdpath <const> = vim.fn.stdpath as function(string): string
local dataPath <const> = stdpath("data")
local configPath <const> = stdpath("config")
local tree <const> = {
	neovim = dataPath .. "/site/pack/package-manager/opt",
	luarocks = dataPath .. "/site/pack/package-manager/luarocks",
	set = configPath .. "/sets",
}

for _, path in pairs(tree as {string:string}) do
	if not fs.exists(path) then
		fs.mkdirp(path)
	end
end

return tree
