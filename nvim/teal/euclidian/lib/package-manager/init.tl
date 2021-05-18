local configure <const> = require("euclidian.lib.package-manager.configure")
local nvim <const> = require("euclidian.lib.nvim")
local loader <const> = require("euclidian.lib.package-manager.loader")
local actions <const> = require("euclidian.lib.package-manager.actions")

local packagemanager <const> = {
	commands = {
		Add = actions.add,
		Install = actions.install,
		Update = actions.update,
		View = actions.listSets,
		Remove = actions.remove,
		Configure = actions.configure,
	},
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
	for k in pairs(packagemanager.commands as {string:function()}) do
		if k:sub(1, len):lower() == arglead:lower() then
			table.insert(keys, k)
		end
	end
	table.sort(keys)
	return keys
end

function packagemanager._reload()
	local req <const> = require

	writeMsg("recompiling...")

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
			req "euclidian.lib.package-manager"
			writeMsg("reloaded!")
			done = true
		end),
	}
	repeat vim.wait(10)
	until done
end

local cmds <const> = packagemanager.commands as {string:function}
cmds._Reload = packagemanager._reload

nvim.newCommand{
	name = "PackageManager",
	nargs = 1,
	completelist = getCommandCompletion,
	body = function(cmd: string)
		if not cmds[cmd] then
			writeErr("Not a command: %s", tostring(cmd))
			return
		end
		cmds[cmd]()
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
