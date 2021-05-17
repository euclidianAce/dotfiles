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
	Remove = actions.remove,
}

local function writeMsg(str: string, ...: any)
	print("PackageManager:", string.format(str, ...))
end

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

local function copyOpts(opts: packagemanager.SetupOptions): packagemanager.SetupOptions
	return {
		enable = { unpack(opts.enable or {}) },
		maxConcurrentJobs = opts.maxConcurrentJobs,
	}
end

local loadedWith: packagemanager.SetupOptions

function packagemanager._reload()
	local req <const> = require

	writeMsg("recompiling...")

	local err <const> = {}
	require("euclidian.lib.command").spawn{
		command = { "cyan", "build" },
		cwd = os.getenv("DOTFILE_DIR") .. "/nvim",
		onStderrLine = function(line: string)
			table.insert(err, line)
		end,
		onExit = vim.schedule_wrap(function(code: integer)
			if not code or code ~= 0 then
				writeErr("cyan build exited with code %s, did not reload", tostring(code))
				local p <const> = require("euclidian.lib.printmode").printfn("buffer")
				for _, ln in ipairs(err) do
					p((ln:gsub(string.char(27) .. "%[%d+m", "")))
				end
				return
			end

			writeMsg("reloading...")
			for name in pairs(package.loaded) do
				if name:match("^euclidian%.lib%.package%-manager") then
					package.loaded[name] = nil
				end
			end
			;(req "euclidian.lib.package-manager" as function)(loadedWith)
			writeMsg("reloaded!")
		end),
	}
end

packagemanager.commands._Reload = packagemanager._reload

return setmetatable(packagemanager, {
	__call = function(_: packagemanager, opts: packagemanager.SetupOptions)
		loadedWith = copyOpts(opts)

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
