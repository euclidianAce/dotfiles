
local set <const> = require("euclidian.lib.package-manager.set")
local loader <const> = {}

-- TODO: packages need to be loaded before their dependents

-- TODO: ideally, we'd have a custom install location
-- and we just add each path to rtp, but for now, just :packadd

-- Holy shit packadd is cursed

local command <const> = vim.api.nvim_command
local function packadd(pkg: string)
	command(([[packadd %s]]):format(pkg))
end

local function packaddSet(setname: string)
	local pre <const>, post <const> = {}, {}
	local ps <const> = set.load(setname)
	for _, pkg in ipairs(ps) do
		if pkg:isInstalled() then
			if pkg.kind == "git" then
				packadd(pkg.alias or pkg.repo:match("[^/]+$"))
			elseif pkg.kind == "local" then
				table.insert(pre, 1, pkg.path)
				table.insert(post, pkg.path .. "/after")
			end
		end
	end
	local rtp <const> = vim.api.nvim_list_runtime_paths()
	vim.list_extend(pre, rtp)
	vim.list_extend(pre, post)
	command([[set rtp=]] .. table.concat(pre, ","))
end

function loader.enableSet(setname: string)
	-- give some feedback that things got done?
	packaddSet(setname)
	-- print("enabled package set:", setname)
end

return loader
