local fs = require("euclidian.lib.fs")

local stdpath = vim.fn.stdpath
local dataPath = stdpath("data")
local configPath = stdpath("config")
local tree = {
   neovim = dataPath .. "/site/pack/package-manager/opt",
   luarocks = dataPath .. "/site/pack/package-manager/luarocks",
   set = configPath .. "/sets",
}

for _, path in pairs(tree) do
   if not fs.exists(path) then
      fs.mkdirp(path)
   end
end

return tree