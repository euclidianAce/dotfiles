
local cmdf = require("euclidian.lib.util").cmdf
local tree = require("euclidian.lib.package-manager.tree")
local a = vim.api
local pack = {}


package.path = tree.luarocks .. "/share/lua/5.1/?.lua;" ..
tree.luarocks .. "/share/lua/5.1/?/init.lua;" ..
package.path

package.cpath = tree.luarocks .. "/lib/lua/5.1/?.so;" ..
package.cpath

function pack.enableSet(setName)
   require("euclidian.lib.package-manager.loader").enableSet(setName)
end


local c = [[command %s lua require'euclidian.lib.package-manager.interface'.%s()]]
cmdf(c, "PackageViewSets", "viewSets")
cmdf(c, "PackageAdd", "addPackage")


return pack
