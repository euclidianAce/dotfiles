
local cmdf <const> = require("euclidian.lib.util").cmdf
local tree <const> = require("euclidian.lib.package-manager.tree")
local a <const> = vim.api
local pack <const> = {}

-- update the lua path
package.path = tree.luarocks .. "/share/lua/5.1/?.lua;"
	.. tree.luarocks .. "/share/lua/5.1/?/init.lua;"
	.. package.path

package.cpath = tree.luarocks .. "/lib/lua/5.1/?.so;"
	.. package.cpath

function pack.enableSet(setName: string)
	require("euclidian.lib.package-manager.loader").enableSet(setName)
end

-- enable the vim commands for doing stuff
local c <const> = [[command %s lua require'euclidian.lib.package-manager.interface'.%s()]]
cmdf(c, "PackageViewSets", "viewSets")
cmdf(c, "PackageAdd", "addPackage")
-- cmdf(c, "PackageInstallSet", "installSet")

return pack

