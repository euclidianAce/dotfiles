
local cmd = require("euclidian.lib.package-manager.cmd")
local tree = require("euclidian.lib.package-manager.tree")
local Package = require("euclidian.lib.package-manager.Package")
local installer = {}

local function getPackageLocation(p)
   if p.kind == "git" then
      return tree.neovim .. "/" .. (p.alias or p.repo:match("[^/]+$"))
   end
end

function installer.installPackage(p)
   if p.kind == "git" then
      cmd.git.clone("install", p.repo)
   end
end

function installer.updatePackage(p)
   if p.kind == "git" then
      cmd.git.pull("pull", getPackageLocation(p))
   end
end

return installer
