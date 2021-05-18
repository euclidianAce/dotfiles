local tree <const> = require("euclidian.lib.package-manager.tree")

local record Options
	enable: {string}
	maxConcurrentJobs: integer
end

local function fillWithDefaults(opts: Options)
	opts.enable = opts.enable or {}
	opts.maxConcurrentJobs = opts.maxConcurrentJobs or 2
end

local configure <const> = {
	Options = Options,
}

local filename <const> = ".Config"

function configure.load(): Options, string
	local fh <const>, err <const> = io.open(tree.set .. "/" .. filename, "r")
	if not fh then
		if err:match("No such file or directory") then
			local wfh <const> = assert(io.open(tree.set .. "/" .. filename, "w"))
			wfh:write("return {}")
			wfh:close()
			local o <const> = {}
			fillWithDefaults(o)
			return o
		end
		return nil, err
	end
	local content <const> = fh:read("*a")
	fh:close()

	local chunk <const>, loaderr <const> = loadstring(content)
	if not chunk then
		return nil, loaderr
	end
	local ok <const>, res <const> = pcall(chunk)
	if not ok then
		return nil, res as string
	end
	if not res is table then
		return nil, "Expected a table"
	end
	fillWithDefaults(res as Options)
	return res as Options
end

function configure.save(opts: Options): boolean, string
	local fh <const>, err <const> = io.open(tree.set .. "/" .. filename, "w")
	if not fh then
		return false, err
	end
	fh:write("return {\n")
	fh:write("   enable = {\n")
	for _, s in ipairs(opts.enable) do
		fh:write(("      %q,\n"):format(s))
	end
	fh:write("   },\n")
	fh:write(("   maxConcurrentJobs = %d,\n"):format(opts.maxConcurrentJobs or 2))
	fh:write("}")

	fh:close()
	return true
end

return configure
