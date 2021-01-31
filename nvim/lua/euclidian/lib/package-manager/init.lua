
local cmdf = require("euclidian.lib.util").cmdf
local manager = {}

local interface = require("euclidian.lib.package-manager.interface")

local commands = {
   ["Install"] = interface.installSet,
   ["Update"] = interface.updateSet,
   ["Add"] = interface.addPackage,
}

function manager.command(cmdName)
   local cmd = commands[cmdName]
   if not cmd then
      return
   end
   cmd()
end

for name in pairs(commands) do
   cmdf(
   [[command -nargs=0 PackageManager%s lua require'euclidian.lib.package-manager'.command(%q)]],
   name, name)

end

require("euclidian.lib.package-manager.tree")

return manager
