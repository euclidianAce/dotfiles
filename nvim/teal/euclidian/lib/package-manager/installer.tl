
local cmd <const> = require("euclidian.lib.package-manager.cmd")
local tree <const> = require("euclidian.lib.package-manager.tree")
local Package <const> = require("euclidian.lib.package-manager.Package")
local installer <const> = {}

local function getPackageLocation(p: Package.Spec): string
	if p.kind == "git" then
		return tree.neovim .. "/" .. (p.alias or p.repo:match("[^/]+$"))
	end
end

function installer.installPackage(p: Package.Spec)
	if p.kind == "git" then
		cmd.git.clone("install", p.repo)
	end
end

function installer.updatePackage(p: Package.Spec)
	if p.kind == "git" then
		cmd.git.pull("pull", getPackageLocation(p))
	end
end

return installer

