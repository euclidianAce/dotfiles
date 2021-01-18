
local cmdf <const> = require("euclidian.lib.util").cmdf
local manager <const> = {}

local interface <const> = require("euclidian.lib.package-manager.interface")
local commands <const>: {string:function} = {
	["Install"] = interface.installSet,
	["Update"] = interface.updateSet,
}

function manager.command(cmdName: string)
	local cmd <const> = commands[cmdName]
	if not cmd then
		return
	end
	cmd()
end

for name in pairs(commands) do
	cmdf(
		[[command -nargs=0 PackageManager%s lua require'euclidian.lib.package-manager'.command(%q)]],
		name, name
	)
end

return manager
