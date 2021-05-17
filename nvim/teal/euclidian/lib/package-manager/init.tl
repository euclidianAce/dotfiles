
local record packagemanager
	record SetupOptions
		enable: {string}
		maxConcurrentJobs: integer
	end

	commands: {string:function}

	metamethod __call: function(any, SetupOptions)
end

local nvim <const> = require("euclidian.lib.nvim")
local loader <const> = require("euclidian.lib.package-manager.loader")
local actions <const> = require("euclidian.lib.package-manager.actions")

packagemanager.commands = {
	Add = actions.add,
	Install = actions.install,
	Update = actions.update,
	View = actions.listSets,
}

local function writeErr(str: string, ...: any)
	vim.api.nvim_err_write("PackageManager: ")
	vim.api.nvim_err_writeln(string.format(str, ...))
end

local function getCommandCompletion(arglead: string): {string}
	arglead = arglead or ""
	local keys <const> = {}
	local len <const> = #arglead
	for k in pairs(packagemanager.commands) do
		if k:sub(1, len):lower() == arglead:lower() then
			table.insert(keys, k)
		end
	end
	table.sort(keys)
	return keys
end

return setmetatable(packagemanager, {
	__call = function(_: packagemanager, opts: packagemanager.SetupOptions)

		nvim.newCommand{
			name = "PackageManager",
			nargs = 1,
			completelist = getCommandCompletion,
			body = function(cmd: string)
				if not packagemanager.commands[cmd] then
					writeErr("Not a command: %s", tostring(cmd))
					return
				end
				packagemanager.commands[cmd]()
			end,

			overwrite = true,
		}

		if not opts then return end
		if opts.maxConcurrentJobs then
			if opts.maxConcurrentJobs <= 0 then
				writeErr("maxConcurrentJobs should be a positive integer, got %s", tostring(opts.maxConcurrentJobs))
			else
				actions.maxConcurrentJobs = opts.maxConcurrentJobs
			end
		end

		if opts.enable then
			for _, s in ipairs(opts.enable) do
				loader.enableSet(s)
			end
		end
	end
})
