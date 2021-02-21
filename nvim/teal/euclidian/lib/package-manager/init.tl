
local nvim <const> = require("euclidian.lib.nvim")
local interface <const> = require("euclidian.lib.package-manager.interface")
local loader <const> = require("euclidian.lib.package-manager.loader")
local tree <const> = require("euclidian.lib.package-manager.tree")

local commands <const>: {string:function} = {
	["Install"] = interface.installSet,
	["Update"] = interface.updateSet,
	["Add"] = interface.addPackage,
}

local record manager
	record SetupOpts
		enable: {string}
	end

	metamethod __call: function(manager, SetupOpts)
end

function manager.command(cmdName: string)
	local cmd <const> = commands[cmdName]
	if not cmd then
		return
	end
	cmd()
end

for name in pairs(commands) do
	nvim.command(
		[[command -nargs=0 PackageManager%s lua require'euclidian.lib.package-manager'.command(%q)]],
		name, name
	)
end

package.path = tree.luarocks .. "/share/lua/5.1/?.lua;"
	.. tree.luarocks .. "/share/lua/5.1/?/init.lua;"
	.. package.path

package.cpath = tree.luarocks .. "/lib/lua/5.1/?.so;"
	.. package.cpath

return setmetatable(manager, {
	__call = function(_: manager, opts: manager.SetupOpts)
		for _, setname in ipairs(opts.enable) do
			loader.enableSet(setname)
		end
	end,
})
