
local tree <const> = require("euclidian.lib.package-manager.tree")
local uv <const> = vim.loop

local enum Kind
	"git" "local"
end

local record Spec
	opt: boolean

	id: integer
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

local spec_mt <const> = { __index = Spec } as metatable<Spec>
function packagespec.new(p: Spec): Spec
	return setmetatable(p, spec_mt)
end

function Spec:locationInTree(): string
	if self.kind == "git" then
		if self.alias then
			return self.alias
		else
			return self.repo:match("[^/]+$")
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
		return self.repo .. (self.alias and " (" .. self.alias .. ")" or "")
	elseif self.kind == "local" then
		return self.path
	end
end

function Spec:installCmd(): {string}
	if self.kind == "git" then
		return { "git", "clone", "https://github.com/" .. self.repo, self:location() }
	end
end

local function fileExists(fname: string): boolean
	return uv.fs_stat(fname) ~= nil
end

function Spec:isInstalled(): boolean
	if self.kind == "git" then
		return fileExists(self:location())
	else
		return true
	end
end

return packagespec

