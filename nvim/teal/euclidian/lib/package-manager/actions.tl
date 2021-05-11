
local nvim <const> = require("euclidian.lib.nvim")
local command <const> = require("euclidian.lib.command")
local dialog <const> = require("euclidian.lib.dialog")
local packagespec <const> = require("euclidian.lib.package-manager.packagespec")
local set <const> = require("euclidian.lib.package-manager.set")
local z <const> = require("euclidian.lib.async.zig")

local type NilFrame = z.Frame<nil>

local actions <const> = {
	maxConcurrentJobs = 2,
	listSets: function(): NilFrame = nil,
	update: function(): NilFrame = nil,
	install: function(): NilFrame = nil,
	add: function(): NilFrame = nil,
}

local type Spec = packagespec.Spec
local type Dialog = dialog.Dialog
local function setCmp(a: Spec, b: Spec): boolean
	return a:title() < b:title()
end

local function createDialog(fn: function(Dialog)): function(): NilFrame
	return function(): NilFrame
		local d <const> = dialog.new{
			wid = 35, hei = 17, centered = true,
			interactive = true,
			ephemeral = true,
		}
		d:win():setOption("wrap", false)
		return z.async(fn as function, d) as NilFrame
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
	local function getPkgNames(s: {Spec}): {string}
		local pkgNames <const> = {}
		for i, v in ipairs(s) do
			pkgNames[i] = v:title()
		end
		return pkgNames
	end

	local function askForDependents(d: Dialog, s: {Spec}, p: Spec)
		if yesOrNo(d, "Does other packages depend on this package?") then
			local deps <const> = checklist(d, "Dependents:", getPkgNames(s))
			for _, idx in ipairs(deps) do
				table.insert(p.dependents, s[idx])
			end
		end
	end

	local function askForDependencies(d: Dialog, s: {Spec}, p: Spec)
		if yesOrNo(d, "Does this package depend on other packages?") then
			local deps <const> = checklist(d, "Dependencies:", getPkgNames())
			for _, idx in ipairs(deps) do
				if not s[idx].dependents then
					s[idx].dependents = {}
				end
				table.insert(s[idx].dependents, p)
			end
		end
	end

	local function addVimPlugPackage()
		print("Vim Plug Package: not yet implemented")
		--local function parseVimPlug(str)
		--	local expr = str:match("^%s*Plug%s+(.*)$")
		--	if not expr then
		--		return nil, "Expected 'Plug'"
		--	end
		--	local name, pos = expr:match("^(%b'')()")
		--	if not name then
		--		name, pos = expr:match("^(%b\"\")()")
		--	end
		--	if not name then
		--		return nil, "Expected string literal after 'Plug'"
		--	end
		--
		--	local val = { name = name }
		--
		--	local dictBody = expr:sub(pos):match("%s*,%s{%s*(.*)%s*}%s*$")
		--	if dictBody then
		--		print("[debug] ", dictBody)
		--		for k, v in dictBody:gmatch("%s*(.-)%s*:%s*(.*)%s*") do
		--			print(key, val)
		--			val[k] = v
		--		end
		--	end
		--
		--	return val
		--end
	end
	local function addPackerPackage()
		print("Packer Package: not yet implemented")
		-- define a "use" function and just run it
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
		askForDependencies(d, s, p)
		askForDependents(d, s, p)
		table.insert(s, p)
	end
	local function addLocalPackage(d: Dialog, s: {Spec})
		d:setLines{}
		local path <const> = prompt(d, "Path: ")
		local p <const>: Spec = {
			kind = "local",
			dependents = {},
			path = path,
		}
		table.insert(s, p)
	end
	-- local function addLuaRock(d: Dialog, s: Spec)
		-- d:setLines{}
		-- local name <const> = prompt(d, "Name: ")
	-- end
	local handlers <const>: {integer:function(Dialog, {Spec})} = {
		[1] = addVimPlugPackage,
		[2] = addPackerPackage,
		[3] = addGitPackage,
		[4] = addLocalPackage,
		-- [5] = addLuaRock,
	}

	actions.add = createDialog(function(d: Dialog)
		local loaded <const>, name <const> = chooseAndLoadSet(d)

		d:setLines{
			"Add new package:",
			"  from Vim-Plug expression",
			"  from Packer expression",
			"  git",
			"  local",
			-- "  lua rock",
		}:fitText(35):center()

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

actions.update = createDialog(function(d: Dialog)
	local loaded <const> = chooseAndLoadSet(d)

	local lines <const> = {}
	for i, pkg in ipairs(loaded) do
		lines[i] = " " .. pkg:title() .. (" "):rep(10)
	end
	d:setLines(lines):fitText(nvim.ui().width - 5, 14):center()

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
			local r <const> = d:claimRegion(
				{ line = i-1, char = #pkg:title() + 4 },
				1, 0
			)
			local updateTxt <const> = vim.schedule_wrap(function(ln: string)
				r:set(ln, true)
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
		while running < actions.maxConcurrentJobs and #jobqueue > 0 do
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
		if not pkg:isInstalled() then
			if pkg.kind == "git" then
				local updateTxt <const> = vim.schedule_wrap(function(ln: string)
					-- TODO: do some fancier setText things

					d:setLine(i-1, " " .. pkg:title() .. ": " .. ln)
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
		while running < actions.maxConcurrentJobs and #jobqueue > 0 do
			table.remove(jobqueue, math.random(1, #jobqueue))()
		end
		z.suspend()
	end

	waitForKey(d, "<cr>")
	d:close()
end)

return actions
