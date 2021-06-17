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

return fs
