
local record packagemanager
	record SetupOptions
		enable: {string}
	end

	commands: {string:function}

	metamethod __call: function(any, SetupOptions)
end

local nvim <const> = require("euclidian.lib.nvim")
local loader <const> = require("euclidian.lib.package-manager.loader")
local actions <const> = require("euclidian.lib.package-manager.actions")

packagemanager.commands = {
	View = actions.listSets,
	Install = actions.install,
	Update = actions.update,
	Add = actions.add,
}

return setmetatable(packagemanager, {
	__call = function(_: packagemanager, opts: packagemanager.SetupOptions)

		nvim.command[[ command -nargs=1 PackageManager lua require'euclidian.lib.package-manager'.commands['<args>']() ]]

		if not opts then return end
		for _, s in ipairs(opts.enable or {}) do
			loader.enableSet(s)
		end
	end
})
