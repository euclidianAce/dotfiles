local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pairs = _tl_compat and _tl_compat.pairs or pairs; local table = _tl_compat and _tl_compat.table or table
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
      uv.fs_mkdir(table.concat(components, "/", 1, i), tonumber("755", 8))
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