local actions <const> = require("euclidian.plug.package-manager.actions")
local configure <const> = require("euclidian.plug.package-manager.configure")
local loader <const> = require("euclidian.plug.package-manager.loader")
local nvim <const> = require("euclidian.lib.nvim")
local report <const> = require("euclidian.plug.package-manager.report")

local packagemanager <const> = {
	commands: {string:function()} = {
		Add = actions.add,
		Install = actions.install,
		Update = actions.update,
		View = actions.listSets,
		Remove = actions.remove,
		Configure = actions.configure,
	},
}

local function getCommandCompletion(arglead: string): {string}
	arglead = arglead or ""
	local keys <const> = {}
	local len <const> = #arglead
	for k in pairs(packagemanager.commands) do
		if k:sub(1, 1) ~= "_" and k:sub(1, len):lower() == arglead:lower() then
			table.insert(keys, k)
		end
	end
	table.sort(keys)
	return keys
end

function packagemanager._reload()
	local req <const> = require

	report.msg("recompiling...")

	local err <const> = {}
	local done = false
	require("euclidian.lib.command").spawn{
		command = { "cyan", "build" },
		cwd = os.getenv("DOTFILE_DIR") .. "/nvim",
		onStderrLine = function(line: string)
			table.insert(err, line)
		end,
		onExit = vim.schedule_wrap(function(code: integer)
			if not code or code ~= 0 then
				report.err("cyan build exited with code %s, did not reload", tostring(code))
				local p <const> = require("euclidian.lib.printmode").printfn("buffer")
				for _, ln in ipairs(err) do
					p((ln:gsub(string.char(27) .. "%[%d+m", "")))
				end
				return
			end

			report.msg("reloading...")
			for name in pairs(package.loaded) do
				if name:match("^euclidian%.plug%.package%-manager") then
					package.loaded[name] = nil
				end
			end
			req "euclidian.plug.package-manager"
			report.msg("reloaded!")
			done = true
		end) as function(integer),
	}
	repeat vim.wait(10)
	until done
end

packagemanager.commands._Reload = packagemanager._reload

nvim.newCommand{
	name = "PackageManager",
	nargs = 1,
	completelist = getCommandCompletion,
	body = function(cmd: string)
		if not packagemanager.commands[cmd] then
			report.err("Not a command: %s", tostring(cmd))
			return
		end
		packagemanager.commands[cmd]()
	end,
	bar = true,

	overwrite = true,
}

local cfg <const> = assert(configure.load())

if cfg.maxConcurrentJobs then
	actions.maxConcurrentJobs = cfg.maxConcurrentJobs
end

for _, s in ipairs(cfg.enable) do
	loader.enableSet(s)
end

nvim.command("packloadall")
