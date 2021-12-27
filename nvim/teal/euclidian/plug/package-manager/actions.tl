local command <const> = require("euclidian.lib.command")
local configure <const> = require("euclidian.plug.package-manager.configure")
local dialog <const> = require("euclidian.lib.dialog")
local menu <const> = require("euclidian.lib.menu")
local nvim <const> = require("euclidian.lib.nvim")
local packagespec <const> = require("euclidian.plug.package-manager.packagespec")
local report <const> = require("euclidian.plug.package-manager.report")
local set <const> = require("euclidian.plug.package-manager.set")
local tu <const> = require("euclidian.lib.textutils")
-- local validate <const> = require("euclidian.lib.validate")
local z <const> = require("euclidian.lib.azync")

local type NilFrame = z.Frame<nil>
local type Action = function(): NilFrame

local actions <const> = {
	maxConcurrentJobs = 2,

	listSets: Action = nil,
	update: Action = nil,
	install: Action = nil,
	add: Action = nil,
	remove: Action = nil,
	configure: Action = nil,
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
		return z.async(fn, d) as NilFrame
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

actions.listSets = function(): NilFrame
	local menuOpts <const> = {}
	for i, s in ipairs(set.list()) do
		local pkgs <const> = set.load(s)
		table.sort(pkgs, setCmp)
		local names <const> = {}
		for j, spec in ipairs(pkgs) do
			names[j] = {spec:title()}
		end
		menuOpts[i] = {s, names}
	end
	local m <const> = menu.new.accordion(menuOpts)
	return z.async(m, dialog.new{
		centered = true,
		wid = .75,
		hei = .3,
		interactive = true,
		ephemeral = true,
	}) as NilFrame
end

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
	affirm = affirm or "Yes"
	deny = deny or "No"
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
		local repo <const> = prompt(d, "Repo: https://github.com/")
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
			d:setLine(i - 1, tu.rightAlign(pkg:title(), titleWidth) .. ": ")
			local r <const> = d:claimRegion(
				{ line = i - 1, char = titleWidth + 2 },
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
					onStdoutLine = updateTxt,
					onStderrLine = updateTxt,
					onExit = function()
						running = running - 1
						r:set("Done!", true)
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

local function showTitles(d: Dialog, loaded: {Spec}, rightAlign: boolean)
	local lines <const> = {}
	local titles <const> = vim.tbl_map(function(p: Spec): string return p:title() end, loaded) as {string}
	local longest <const> = longestInList(titles)
	for i, title in ipairs(titles) do
		local limited = tu.limit(title, 35, true)
		if rightAlign then
			limited = tu.rightAlign(limited, longest + 1)
		end
		lines[i] = limited .. " "
	end
	d:setLines(lines):fitText(nvim.ui().width - 20, 14):center()
end

actions.remove = createDialog(function(d: Dialog)
	local loaded <const>, name <const> = chooseAndLoadSet(d)
	table.sort(loaded)

	showTitles(d, loaded)

	-- TODO: this should probably be a checklist
	waitForKey(d, "<cr>")
	local ln <const> = d:getCursor()
	local selected <const> = loaded[ln]

	if selected.dependents and next(selected.dependents) then
		local lns <const> = { "Selected package: " .. selected:title() .. " is a dependency for:" }
		for _, p in ipairs(selected.dependents) do
			table.insert(lns, "   " .. assert(p is Spec and p):title())
		end
		d:setLines(lns)
		waitForKey(d, "<cr>")
		d:close()
		return
	end

	table.remove(loaded, ln)
	local ok <const>, err <const> = set.save(name, loaded)

	if ok then
		d:setLines{ "Removed package: " .. selected:title() }:fitText():center()
	else
		d:setLines{
			"Unable to remove package: " .. selected:title(),
			err
		}:fitText():center()
	end

	waitForKey(d, "<cr>")
	d:close()
end)

actions.update = createDialog(function(d: Dialog)
	local loaded <const> = chooseAndLoadSet(d)
	showTitles(d, loaded, true)
	runCmdForEachPkg(d, Spec.updateCmd, loaded)
	waitForKey(d, "<cr>")
	d:close()
end)

actions.install = createDialog(function(d: Dialog)
	local loaded <const> = chooseAndLoadSet(d)
	showTitles(d, loaded, true)
	runCmdForEachPkg(d, Spec.installCmd, loaded)
	waitForKey(d, "<cr>")
	d:close()
end)

actions.configure = createDialog(function(d: Dialog)
	local cfg <const>, err <const> = configure.load()
	if err then
		-- TODO: allow some sort of recovery
		d:setLines{ "There was an error loading your config:", err }
		waitForKey(d, "<cr>", "<bs>")
		d:close()
		return
	end

	local addLine: function(string, ...: any)
	local addHandler: function(function)
	local getHandler: function(integer): function
	local show: function()
	local clear: function()
	do
		-- latest line that handles the option -> the function that updates that option
		local handlers: {integer:function} = {}
		local txt: {string} = {}

		addLine = function(fmt: string, ...: any)
			tu.insertFormatted(txt, fmt, ...)
		end
		addHandler = function(fn: function)
			handlers[#txt] = fn
		end
		getHandler = function(ln: integer): function
			for i = ln, #txt do
				if handlers[i] then
					return handlers[i]
				end
			end
		end
		show = function()
			d:setLines(txt):fitText(35, 17):center()
		end
		clear = function()
			txt = {}
			handlers = {}
			d:setLines{}
		end
	end

	local function updateUintOptHandler(prefix: string, field: string): function()
		return function()
			clear()
			local result <const> = prompt(d, prefix)
			local numResult <const> = tonumber(result)
			if not numResult then
				print("expected a number")
				return
			end
			if numResult <= 0 or math.floor(numResult) ~= numResult then
				print("expected a positive integer")
				return
			end
			;(cfg as table)[field] = numResult as integer
		end
	end

	-- local checkInt <const> = validate.type("number") + validate.new(function(val: any): boolean, string
		-- if math.floor(val as number) ~= val then
			-- return false, tostring(val) .. " is not an integer"
		-- end
		-- return true
	-- end)
	-- local checkUint <const> = checkInt + validate.range(0, math.huge)
	-- local checkString <const> = validate.type("string")

	local function appendToStringListHandler(prefix: string, field: string): function()
		return function()
			clear()
			local result <const> = prompt(d, prefix)
			if result ~= "" then
				table.insert((cfg as {string:{string}})[field], result)
			end
		end
	end

	local function fillDialog()
		clear()
		addLine("Enabled Sets:")
		table.sort(cfg.enable)
		for _, s in ipairs(cfg.enable) do
			addLine("   %s", s)
		end
		addHandler(appendToStringListHandler("Add Set: ", "enable"))

		addLine("Max Concurrent Jobs: %d", cfg.maxConcurrentJobs)
		addHandler(updateUintOptHandler("Max Concurrent Jobs: ", "maxConcurrentJobs"))
	end

	fillDialog()
	show()

	while waitForKey(d, "<cr>", "<bs>") == "<cr>" do
		local ln <const>, col <const> = d:getCursor()
		local handler <const> = getHandler(ln)
		if handler then
			handler()
			fillDialog()
			show()
			d:setCursor(ln, col)
		end
	end

	configure.save(cfg)
	report.msg("Configuration saved!")
	d:close()
end)

return actions
