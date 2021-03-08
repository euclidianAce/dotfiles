local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local package = _tl_compat and _tl_compat.package or package; local pairs = _tl_compat and _tl_compat.pairs or pairs
local nvim = require("euclidian.lib.nvim")
local interface = require("euclidian.lib.package-manager.interface")
local loader = require("euclidian.lib.package-manager.loader")
local tree = require("euclidian.lib.package-manager.tree")

local commands = {
   ["Install"] = interface.installSet,
   ["Update"] = interface.updateSet,
   ["Add"] = interface.addPackage,
   ["View"] = interface.showSets,
}

local manager = {SetupOpts = {}, }







function manager.command(cmdName)
   local cmd = commands[cmdName]
   if not cmd then
      return
   end
   cmd()
end

for name in pairs(commands) do
   nvim.command(
   [[command -nargs=0 PackageManager%s lua require'euclidian.lib.package-manager'.command(%q)]],
   name, name)

end

package.path = tree.luarocks .. "/share/lua/5.1/?.lua;" ..
tree.luarocks .. "/share/lua/5.1/?/init.lua;" ..
package.path

package.cpath = tree.luarocks .. "/lib/lua/5.1/?.so;" ..
package.cpath

return setmetatable(manager, {
   __call = function(_, opts)
      for _, setname in ipairs(opts.enable) do
         loader.enableSet(setname)
      end
   end,
})