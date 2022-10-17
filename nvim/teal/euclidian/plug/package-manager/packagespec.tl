local fs <const> = require("euclidian.lib.fs")
local tree <const> = require("euclidian.plug.package-manager.tree")

local enum Kind
	"git"
	"local"
end

local record Spec
	opt: boolean

	id: integer
	dependents: {integer | Spec}

	kind: Kind

	-- git
	remote: string
	branch: string
	alias: string

	-- local
	path: string

	title: function(Spec): string
	metamethod __lt: function(Spec, Spec): boolean
end

local packagespec <const> = {
	Spec = Spec,
	Kind = Kind,
	kinds: {Kind:boolean} = {
		["git"] = true,
		["local"] = true,
	},
}

local spec_mt <const>: metatable<Spec> = {
	__index = Spec,
	__lt = function(a: Spec, b: Spec): boolean
		return a:title() < b:title()
	end
}
function packagespec.new(p: Spec): Spec
	return setmetatable(p, spec_mt)
end

function Spec:locationInTree(): string
	if self.kind == "git" then
		if self.alias then
			return self.alias
		else
			local loc = self.remote:match("[^/]+$")
			if loc:match("%.git$") then
				return loc:sub(1, -5)
			end
			return loc
		end
	end
end

function Spec:location(): string
	if self.kind == "git" then
		return tree.neovim .. "/" .. self:locationInTree()
	elseif self.kind == "local" then
		return self.path
	end
end

function Spec:title(): string
	if self.kind == "git" then
		return self.remote .. (self.alias and " (" .. self.alias .. ")" or "")
	elseif self.kind == "local" then
		return self.path
	end
end

function Spec:installCmd(): {string}
	if self.kind == "git" then
		return { "git", "clone", "--progress", "--depth=1", self.remote, self:location() }
	end
end

function Spec:updateCmd(): {string}
	if self.kind == "git" then
		return { "git", "-C", self:location(), "pull" }
	end
end

function Spec:isInstalled(): boolean
	if self.kind == "git" then
		return fs.exists(self:location())
	else
		return true
	end
end

return packagespec

