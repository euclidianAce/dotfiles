
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
		vim.schedule(function()
			for _, key in ipairs(keys) do
				d:delKeymap("n", key)
			end
		end)
	end
	local pressed: string
	local me <const> = assert(z.currentFrame(), "attempt to waitForKey not in a coroutine")
	vim.schedule(function()
		for _, key in ipairs(keys) do
			d:addKeymap("n", key, function()
				pressed = key
				delKeymaps()
				z.resume(me)
			end, { noremap = true, silent = true })
		end
	end)
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
	}:fitText():center()
	d:win():setOption("cursorline", true)
	local ln: integer
	repeat
		waitForKey(d, "<cr>")
		ln = d:getCursor()
	until ln > 1
	d:win():setOption("cursorline", false)
	return ln == 2
end

local checkKey <const> = "a"
local function checklist(d: Dialog, pre: string, opts: {string}): {integer}
	d:win():setOption("number", true)
	d:win():setOption("relativenumber", true)
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
	d:win():setOption("number", false)
	d:win():setOption("relativenumber", false)
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
		if yesOrNo(d, "Do any other packages depend on this package?") then
			local deps <const> = checklist(d, "Dependents:", getPkgNames(s))
			for _, idx in ipairs(deps) do
				table.insert(p.dependents, s[idx])
			end
		end
	end

	local function askForDependencies(d: Dialog, s: {Spec}, p: Spec)
		if yesOrNo(d, "Does this package depend on other packages?") then
			local deps <const> = checklist(d, "Dependencies:", getPkgNames(s))
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
	local function addGitHubPackage(d: Dialog, s: {Spec})
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
		addGitHubPackage,
		addLocalPackage,
		addVimPlugPackage,
		addPackerPackage,
		-- addLuaRock,
	}

	actions.add = createDialog(function(d: Dialog)
		local loaded <const>, name <const> = chooseAndLoadSet(d)

		d:setLines{
			"Add new package from:",
			"  Github",
			"  Local directory",
			"  Vim-Plug expression",
			"  Packer expression",
			-- "  lua rock",
		}:fitText(35):center()

		local ln: integer
		repeat
			waitForKey(d, "<cr>")
			ln = d:getCursor()
		until ln > 1

		set.save("." .. name .. "__bak", loaded)
		handlers[ln - 1](d, loaded)
		set.save(name, loaded)
		d:close()
	end)
end

-- local function asyncCmd(opts: command.SpawnOpts)
	-- local running = true
	-- local origExit <const> = opts.onExit
	-- opts.onExit = function(a: integer, b: integer)
		-- if origExit then
			-- origExit(a, b)
		-- end
		-- running = false
	-- end
	-- command.spawn(opts)
	-- while running do
		-- z.suspend()
	-- end
-- end

local titleWidth <const> = 35
local scheduleWrap <const> = vim.schedule_wrap
	as function<Args..., Rets...>(function(Args): Rets): function(Args)

local function runCmdForEachPkg(d: Dialog, getcmd: (function(Spec): {string}), loaded: {Spec})
	local mainTask <const> = z.currentFrame()

	local jobqueue <const> = {}
	local running = 0

	for i, pkg in ipairs(loaded) do
		local cmd <const> = getcmd(pkg)
		if cmd then
			local r <const> = d:claimRegion(
				{ line = i - 1, char = titleWidth + 1 },
				1, 0
			)

			local updateTxt <const> = scheduleWrap(function(ln: string)
				if #ln > 0 then
					r:set(ln, true)
				end
			end)

			table.insert(jobqueue, function()
				running = running + 1
				command.spawn{
					command = cmd,
					-- TODO: stderr and stdout can kind of race with each other
					-- Make an explicit indicator that a cmd is done in the dialog
					onStdoutLine = updateTxt,
					onStderrLine = updateTxt,
					onExit = function()
						running = running - 1
						z.resume(mainTask)
					end,
				}
			end)
		else
			d:setLine(i-1, pkg:title() .. ": nothing to be done")
		end
	end

	local function spawnJob()
		assert(table.remove(jobqueue, math.random(1, #jobqueue)))()
	end

	while next(jobqueue) or running > 0 do
		while running < actions.maxConcurrentJobs and next(jobqueue) do
			spawnJob()
		end
		z.suspend()
	end

	assert(running == 0, "mainTask finished with jobs still running")
	assert(not next(jobqueue), "mainTask finished with jobs still queued")
end

-- local function dummyUpdateCmd(p: Spec): {string}
	-- local cmd <const> = {}
	-- for i = 1, 10 do
		-- table.insert(cmd, "echo " .. ("="):rep(i))
		-- table.insert(cmd, "sleep " .. math.random(0.05, 0.1))
	-- end
	-- return {
		-- "sh", "-c",
		-- table.concat(cmd, "; ")
			-- .. "; echo " .. p:title() .. " done!"
	-- }
-- end

local function longestInList(list: {string}): integer
	local len = 0
	for _, v in ipairs(list) do
		local itemLen <const> = #v
		if itemLen > len then
			len = itemLen
		end
	end
	return len
end

local function applyPadding(s: string, len: integer): string
	if #s > titleWidth then
		s = s:sub(1, 35)
	end
	return (" "):rep(len - #s) .. s .. " "
end

local function showTitles(d: Dialog, loaded: {Spec})
	local lines <const> = {}
	local titles <const> = vim.tbl_map(function(p: Spec): string return p:title() end, loaded) as {string}
	local longest <const> = longestInList(titles)
	for i, title in ipairs(titles) do
		lines[i] = applyPadding(title, longest + 1)
	end
	d:setLines(lines):fitText(nvim.ui().width - 20, 14):center()
end

actions.update = createDialog(function(d: Dialog)
	local loaded <const> = chooseAndLoadSet(d)
	showTitles(d, loaded)
	runCmdForEachPkg(d, Spec.updateCmd, loaded)
	waitForKey(d, "<cr>")
	d:close()
end)

actions.install = createDialog(function(d: Dialog)
	local loaded <const> = chooseAndLoadSet(d)
	showTitles(d, loaded)
	runCmdForEachPkg(d, Spec.installCmd, loaded)
	waitForKey(d, "<cr>")
	d:close()
end)

return actions
