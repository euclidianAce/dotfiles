
local command <const> = require("euclidian.lib.command")
local dialog <const> = require("euclidian.lib.dialog")
local packagespec <const> = require("euclidian.lib.package-manager.packagespec")
local set <const> = require("euclidian.lib.package-manager.set")
local z <const> = require("euclidian.lib.async.zig")

local actions <const> = {
	listSets: function(): z.Frame<nil> = nil,
	update: function(): z.Frame<nil> = nil,
	install: function(): z.Frame<nil> = nil,
	add: function(): z.Frame<nil> = nil,
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
	local me <const> = assert(z.currentFrame(), "attempt to waitForKey not in a coroutine")
	for _, key in ipairs(keys) do
		d:addKeymap("n", key, function()
			pressed = key
			delKeymaps()
			z.resume(me)
		end, { noremap = true, silent = true })
	end
	z.suspend()
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

local function chooseAndLoadSet(d: Dialog): {Spec}, string
	local pkgs <const> = set.list()
	table.sort(pkgs)

	d:setLines(pkgs)
	 :fitText(35, 17)
	 :center()

	waitForKey(d, "<cr>")

	local name <const> = d:getCurrentLine()
	return set.load(name), name
end

local function prompt(d: Dialog, promptText: string): string
	local f <const> = z.currentFrame()
	local val: string
	d:setPrompt(promptText, function(s: string)
		print("Prompt: ", s)
		val = s
		d:unsetPrompt()
		vim.schedule(function()
			z.resume(f)
		end)
	end)
	z.suspend()
	return val
end

local function yesOrNo(d: Dialog, pre: string, affirm: string, deny: string): boolean
	affirm = affirm or "yes"
	deny = deny or "no"
	d:setLines{
		pre,
		affirm,
		deny,
	}
	local ln: integer
	repeat
		waitForKey(d, "<cr>")
		ln = d:getCursor()
	until ln > 1
	return ln == 2
end

local checkKey <const> = "a"
local function checklist(d: Dialog, pre: string, opts: {string}): {integer}
	local lines <const> = {}
	for i, v in ipairs(opts) do
		lines[i] = "[ ] " .. v
	end
	table.insert(lines, 1, pre)
	d:setLines(lines):fitText():center()
	d:addKeymap("n", checkKey, function()
		local ln <const> = d:getCursor()
		local l <const> = d:getLine(ln)
		d:setText{{
			l:match"^%[%*" and " " or "*", ln-1, 1, ln-1, 2
		}}
	end, { silent = true, noremap = true })
	waitForKey(d, "<cr>")
	d:delKeymap("n", checkKey)
	local selected <const>: {integer} = {}
	for i, v in ipairs(d:getLines(1, -1)) do
		if v:match"^%[%*" then
			table.insert(selected, i)
		end
	end
	return selected
end

do
	local function addVimPlugPackage()
		print("Vim Plug Package: not yet implemented")
	end
	local function addPackerPackage()
		print("Packer Package: not yet implemented")
	end
	local function addGitPackage(d: Dialog, s: {Spec})
		d:setLines{}
		local repo <const> = prompt(d, "Repo: ")
		local pkgNames <const> = {}
		for i, v in ipairs(s) do
			pkgNames[i] = v:title()
		end
		local p <const>: Spec = {
			kind = "git",
			dependents = {},
			repo = repo,
		}
		if yesOrNo(d, "Does this package depend on other packages?") then
			local deps <const> = checklist(d, "Dependencies:", pkgNames)
			for _, idx in ipairs(deps) do
				if not s[idx].dependents then
					s[idx].dependents = {}
				end
				table.insert(s[idx].dependents, p)
			end
		end
		if yesOrNo(d, "Do other packages depend on this package?") then
			local deps <const> = checklist(d, "Dependents:", pkgNames)
			for _, idx in ipairs(deps) do
				table.insert(p.dependents, s[idx])
			end
		end
		print("Pre insert length: ", #s)
		table.insert(s, p)
		print("Post insert length: ", #s)
		for i, v in ipairs(s) do
			print(i, v.repo)
		end
	end
	local function addLocalPackage()
		print("Local package: Not yet implemented")
	end
	local handlers <const>: {integer:function(Dialog, {Spec})} = {
		[1] = addVimPlugPackage,
		[2] = addPackerPackage,
		[3] = addGitPackage,
		[4] = addLocalPackage,
	}

	actions.add = createDialog(function(d: Dialog)
		local loaded <const>, name <const> = chooseAndLoadSet(d)

		d:setLines{
			"Add new package:",
			"  from Vim-Plug expression",
			"  from Packer expression",
			"  git",
			"  local",
		}:fitText():center()

		local ln: integer
		repeat
			waitForKey(d, "<cr>")
			ln = d:getCursor()
		until ln > 1

		set.save("." .. name .. "__bak", loaded)
		handlers[ln-1](d, loaded)
		set.save(name, loaded)
		d:close()
	end)
end

local maxConcurrent <const> = 2
actions.update = createDialog(function(d: Dialog)
	local loaded <const> = chooseAndLoadSet(d)

	local lines <const> = {}
	for i, pkg in ipairs(loaded) do
		lines[i] = " " .. pkg:title() .. " "
	end
	d:setLines(lines):fitText():center()

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
