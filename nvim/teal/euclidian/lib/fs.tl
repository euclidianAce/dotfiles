local z <const> = require("euclidian.lib.async.zig")
local uv <const> = vim.loop

local fs <const> = {}

function fs.mkdirp(path: string)
	local components <const> = vim.split(path, "/")
	for i = 1, #components do
		uv.fs_mkdir(table.concat(components, "/", 1, i), tonumber("755", 8))
	end
end

function fs.exists(fname: string): boolean
	return uv.fs_stat(fname) ~= nil
end

function fs.ls(dirname: string, show_hidden: boolean): function(): string
	local scanner <const> = uv.fs_scandir(dirname)
	return function(): string
		if not scanner then return end
		local name: string
		repeat
			name = uv.fs_scandir_next(scanner)
			if show_hidden then
				return name
			end
		until not name or name:sub(1,1) ~= "."
		return name
	end
end

local function wrap<Ret, Args...>(fn: (function(Args): Ret)): function(Args): Ret, string
	return function(...: Args): Ret, string
		local n <const> = select("#", ...)
		local args <const> = { ... }
		local frame <const> = z.currentFrame()
		local ret: Ret
		local err: string
		;(args as {any})[n + 1] = function(e: string, r: Ret)
			err = e
			ret = r
			z.resume(frame)
		end
		z.suspend(function()
			fn(unpack(args, 1, n + 1))
		end)
		return ret, err
	end
end

local open <const> = wrap(uv.fs_open)
local fstat <const> = wrap(uv.fs_fstat)
local read <const> = wrap(uv.fs_read)
local write <const> = wrap(uv.fs_write)
local close <const> = wrap(uv.fs_close)

function fs.read(path: string): string, string
	local ok <const>, res <const> = pcall(function(): string
		local fd <const> = assert(open(path, "r", 438))
		local stat <const> = assert(fstat(fd))
		local data <const> = assert(read(fd, stat.size, 0))
		assert(close(fd))
		return data
	end)
	if not ok then
		return nil, res
	end

	return res
end

function fs.write(path: string, data: string | {string}): integer, string
	local ok <const>, res <const> = pcall(function(): integer
		local fd <const> = assert(open(path, "w", 438))
		local r <const> = assert(write(fd, data, 0))
		assert(close(fd))
		return r
	end)
	if not ok then
		return nil, res as string
	end

	return res
end


return fs
