
local set <const> = require("euclidian.lib.package-manager.set")
local loader <const> = {}

local function packadd(package: string)
	vim.api.nvim_command(([[packadd %s]]):format(package))
end

local function packaddSet(setname: string)
	local pre <const>, post <const> = {}, {}
	local ps <const> = set.load(setname)
	for _, pkg in ipairs(ps) do
		if pkg.kind == "git" then
			packadd(pkg.alias or pkg.repo:match("[^/]+$"))
		elseif pkg.kind == "local" then
			-- print("adding", pkg.path, "to rtp")
			table.insert(pre, 1, pkg.path)
			table.insert(post, pkg.path .. "/after")
		end
	end
	local rtp <const> = vim.api.nvim_list_runtime_paths()
	vim.list_extend(pre, rtp)
	vim.list_extend(pre, post)
	vim.api.nvim_command([[set rtp=]] .. table.concat(pre, ","))
end

function loader.enableSet(setname: string)
	-- give some feedback that things got done?
	packaddSet(setname)
	-- print("enabled package set:", setname)
end

return loader

