
local command <const> = require("euclidian.lib.command")
local dialog <const> = require("euclidian.lib.dialog")
local packagespec <const> = require("euclidian.lib.package-manager.packagespec")
local set <const> = require("euclidian.lib.package-manager.set")
local z <const> = require("euclidian.lib.async.zig")

local actions <const> = {
	listSets: function(): z.Frame<nil> = nil,
	update: function(): z.Frame<nil> = nil,
	install: function(): z.Frame<nil> = nil,
}

local type Spec = packagespec.Spec
local type Dialog = dialog.Dialog
local function setCmp(a: Spec, b: Spec): boolean
	return a:title() < b:title()
end

local function createDialog(fn: function(Dialog)): function(): z.Frame<nil>
	return function(): z.Frame<nil>
		local d <const> = dialog.centered(35, 17)
		return z.async(fn as (function(Dialog): nil), d)
	end
end

local function waitForKey(d: Dialog, ...: string): string
	local keys <const> = {...}
	local function delKeymaps()
		for _, key in ipairs(keys) do
			d:delKeymap("n", key)
		end
	end
	local pressed: string
	z.suspend(function(me: z.Frame<nil>)
		for _, key in ipairs(keys) do
			d:addKeymap("n", key, function()
				pressed = key
				delKeymaps()
				z.resume(me)
			end, { noremap = true, silent = true })
		end
	end)
	return pressed
end

actions.listSets = createDialog(function(d: Dialog)
	-- TODO: this should show dependencies/dependents
	repeat
		local pkgs <const> = set.list()
		table.sort(pkgs)

		d:setLines(pkgs)
		 :fitText(35, 17)
		 :center()

	 	if waitForKey(d, "<cr>", "<bs>") == "<bs>" then
			break
		end

		local choice <const> = d:getCurrentLine()
		local loaded <const> = set.load(choice)

		table.sort(loaded, setCmp)
		local txt = {}

		for i, v in ipairs(loaded) do
			txt[i] = v:title()
		end

		d:setLines(txt)
		 :fitText(35, 17)
		 :center()

	until waitForKey(d, "<cr>", "<bs>") == "<cr>"

	d:close()
end)

local function chooseAndLoadSet(d: Dialog): {Spec}
	local pkgs <const> = set.list()
	table.sort(pkgs)

	d:setLines(pkgs)
	 :fitText(35, 17)
	 :center()

	waitForKey(d, "<cr>")

	return set.load(d:getCurrentLine())
end

local maxConcurrent <const> = 2
actions.update = createDialog(function(d: Dialog)
	local loaded <const> = chooseAndLoadSet(d)

	local lines <const> = {}
	for i, pkg in ipairs(loaded) do
		lines[i] = " " .. pkg:title() .. " "
	end
	d:setLines(lines):fitText()

	local main <const> = z.currentFrame()

	local jobsleft = #loaded
	local running = 0

	local onCmdExit <const> = vim.schedule_wrap(function()
		jobsleft = jobsleft - 1
		running = running - 1
		z.resume(main)
	end) as function(integer, integer)

	local jobqueue <const> = {}
	for i, pkg in ipairs(loaded) do
		if pkg.kind == "git" then
			local updateTxt <const> = vim.schedule_wrap(function(ln: string)
				-- TODO: do some fancier setText things

				d:setLine(i-1, " " .. pkg:title() .. ": " .. ln:sub(1, 20) .. " ")
				 :fitText()
				 :center()
			end) as function(string)

			table.insert(jobqueue, function()
				running = running + 1
				command.spawn{
					command = { "git", "pull" },
					cwd = pkg:location(),
					onStdoutLine = updateTxt,
					onStderrLine = updateTxt,
					onExit = onCmdExit,
				}
			end)
		else
			jobsleft = jobsleft - 1
			d:setLine(i-1, pkg:title() .. ": not a git package :D")
		end
	end

	while jobsleft > 0 do
		while running < maxConcurrent and #jobqueue > 0 do
			table.remove(jobqueue, math.random(1, #jobqueue))()
		end
		z.suspend()
	end

	waitForKey(d, "<cr>")
	d:close()
end)

actions.install = createDialog(function(d: Dialog)
	local loaded <const> = chooseAndLoadSet(d)

	local lines <const> = {}
	for i, pkg in ipairs(loaded) do
		lines[i] = " " .. pkg:title() .. " "
	end
	d:setLines(lines):fitText()

	local main <const> = z.currentFrame()

	local jobsleft = #loaded
	local running = 0

	local onCmdExit <const> = vim.schedule_wrap(function()
		jobsleft = jobsleft - 1
		running = running - 1
		z.resume(main)
	end) as function(integer, integer)

	local jobqueue <const> = {}
	for i, pkg in ipairs(loaded) do
		if pkg:isInstalled() then
			if pkg.kind == "git" then
				local updateTxt <const> = vim.schedule_wrap(function(ln: string)
					-- TODO: do some fancier setText things

					d:setLine(i-1, " " .. pkg:title() .. ": " .. ln:sub(1, 20) .. " ")
					 :fitText():center()
				end) as function(string)

				table.insert(jobqueue, function()
					running = running + 1
					command.spawn{
						command = { "git", "clone", "https://github.com/" .. pkg.repo, pkg:location() },
						onStdoutLine = updateTxt,
						onStderrLine = updateTxt,
						onExit = onCmdExit,
					}
				end)
			else
				jobsleft = jobsleft - 1
				d:setLine(i-1, pkg:title() .. ": not a git package :D")
			end
		else
			jobsleft = jobsleft - 1
			d:setLine(i-1, pkg:title() .. ": already installed")
		end
	end

	while jobsleft > 0 do
		while running < maxConcurrent and #jobqueue > 0 do
			table.remove(jobqueue, math.random(1, #jobqueue))()
		end
		z.suspend()
	end

	waitForKey(d, "<cr>")
	d:close()
end)

return actions
