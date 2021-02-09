
local uv = vim.loop

local stdpath = vim.fn.stdpath
local dataPath = stdpath("data")
local tree = {
   neovim = dataPath .. "/site/pack/package-manager/opt",
   luarocks = dataPath .. "/site/pack/package-manager/luarocks",
   set = stdpath("config") .. "/sets",
}

local function mkdirp(path)
   local components = vim.split(path, "/")
   for i = 1, #components do
      uv.fs_mkdir(table.concat(components, "/", 1, i), 0)
   end
end

local function fileExists(fname)
   return uv.fs_stat(fname) ~= nil
end

for _, path in pairs(tree) do
   if not fileExists(path) then
      mkdirp(path)
   end
end

return tree