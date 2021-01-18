
-- local cmd <const> = require("euclidian.lib.package-manager.cmd")
local tree <const> = require("euclidian.lib.package-manager.tree")

local enum Kind
	"git" "local"
end

local record Spec
	opt: boolean

	id: number
	dependents: {number|Spec}

	kind: Kind

	-- git
	repo: string
	branch: string
	alias: string

	-- local
	path: string
end

local packagespec <const> = {
	Spec = Spec,
	Kind = Kind,
	kinds: {Kind:boolean} = {
		["git"] = true,
		["local"] = true,
	},
}

function packagespec.new(p: Spec): Spec
	return setmetatable(p, { __index = Spec })
end

function Spec:location(): string
	if self.kind == "git" then
		if self.alias then
			return tree.neovim .. "/" .. self.alias
		else
			return tree.neovim .. "/" .. self.repo:match("[^/]+$")
		end
	elseif self.kind == "local" then
		return self.path
	end
end

function Spec:title(): string
	if self.kind == "git" then
		return self.repo .. (self.alias and " (" .. self.alias .. ")" or "")
	elseif self.kind == "local" then
		return self.path
	end
end

math.randomseed(os.time())
function Spec:installCmd(): {string}
	if self.kind == "git" then
		-- TODO: this is a simulation of a download with random sleeps and echos
		local cmd = {}
		for i = 1, math.random(3, 10) do
			if math.random() < .5 then
				table.insert(cmd, "sleep " .. tostring(math.random(.01, .5)) .. ";")
			else
				table.insert(cmd, "echo step " .. tostring(i) .. ";")
			end
		end
		table.insert(cmd, "echo git clone https://github.com/" .. self.repo .. " " .. self:location())
		return { "sh", "-c", table.concat(cmd, " ") }
	end
end

local glob <const> = vim.fn.glob as function(string, boolean, boolean): {string}
function Spec:isInstalled(): boolean
	if self.kind == "git" then
		local loc <const> = self:location()
		if glob(loc) then
			return true
		end
	else
		return true
	end
	return false
end

return packagespec

