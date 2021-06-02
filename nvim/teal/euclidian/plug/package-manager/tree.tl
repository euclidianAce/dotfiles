local uv <const> = vim.loop

local stdpath <const> = vim.fn.stdpath as function(string): string
local dataPath <const> = stdpath("data")
local configPath <const> = stdpath("config")
local tree <const> = {
	neovim = dataPath .. "/site/pack/package-manager/opt",
	luarocks = dataPath .. "/site/pack/package-manager/luarocks",
	set = configPath .. "/sets",
}

local function mkdirp(path: string)
	local components <const> = vim.split(path, "/")
	for i = 1, #components do
		uv.fs_mkdir(table.concat(components, "/", 1, i), tonumber("755", 8))
	end
end

local function fileExists(fname: string): boolean
	return uv.fs_stat(fname) ~= nil
end

for _, path in pairs(tree as {string:string}) do
	if not fileExists(path) then
		mkdirp(path)
	end
end

return tree
