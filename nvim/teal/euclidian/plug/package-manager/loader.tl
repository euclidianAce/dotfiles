
local packagespec <const> = require("euclidian.plug.package-manager.packagespec")
local set <const> = require("euclidian.plug.package-manager.set")
local report <const> = require("euclidian.plug.package-manager.report")
local nvim <const> = require("euclidian.lib.nvim")

local loader <const> = {}

local type Spec = packagespec.Spec

local function packadd(pkg: string)
	nvim.command("packadd " .. pkg)
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

function loader.enableSet(setname: string)
	local pre <const>, post <const> = {}, {}
	local loaded <const>, err <const> = set.load(setname)
	if not loaded then
		report.err("Unable to load set %s: %s", setname, err)
		return
	end
	local ps <const> = getLoadOrder(loaded)
	for _, pkg in ipairs(ps) do
		if pkg:isInstalled() then
			if pkg.kind == "git" then
				packadd(pkg:locationInTree())
			elseif pkg.kind == "local" then
				table.insert(pre, 1, pkg.path)
				table.insert(post, pkg.path .. "/after")
			end
		end
	end
	vim.opt.runtimepath:prepend(pre)
	vim.opt.runtimepath:append(post)
end

return loader
