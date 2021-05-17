
local packagespec <const> = require("euclidian.lib.package-manager.packagespec")
local set <const> = require("euclidian.lib.package-manager.set")
local loader <const> = {}

local type Spec = packagespec.Spec

-- TODO: packages need to be loaded before their dependents

-- TODO: ideally, we'd have a custom install location
-- and we just add each path to rtp, but for now, just :packadd

-- Holy shit packadd is cursed

local command <const> = vim.api.nvim_command
local function packadd(pkg: string)
	command(([[packadd %s]]):format(pkg))
end

local function getLoadOrder(loadedSet: {Spec}): {Spec}
	local stages <const>: {{Spec:boolean}} = setmetatable({}, {
		__index = function(self: {{Spec:boolean}}, key: integer): {Spec:boolean}
			rawset(self, key, {})
			return rawget(self, key)
		end
	})

	for _, p in ipairs(loadedSet) do
		stages[1][p] = true
	end

	local idx = 1
	local maxLen <const> = #loadedSet + 1
	repeat
		assert(idx <= maxLen, "circular dependency detected") -- TODO: we should verify this earlier
		local done = true

		for p in pairs(stages[idx]) do
			if p.dependents then
				done = false
				for _, dep in ipairs(p.dependents) do
					stages[idx][dep as Spec] = nil
					stages[idx + 1][dep as Spec] = true
				end
			end
		end
		idx = idx + 1
	until done

	local order <const> = {}
	for _, stage in ipairs(stages) do
		for p in pairs(stage) do
			table.insert(order, p)
		end
	end

	return order
end

local function packaddSet(setname: string)
	local pre <const>, post <const> = {}, {}
	local ps <const> = getLoadOrder(set.load(setname))
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
