local command <const> = require("euclidian.lib.command")
local configure <const> = require("euclidian.plug.package-manager.configure")
local dialog <const> = require("euclidian.lib.dialog")
local input <const> = require("euclidian.lib.input")
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

	view: Action = nil,
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

local function defaultDialog(): Dialog
	return dialog.new{
		centered = true,
		wid = .75,
		hei = .3,
		interactive = true,
		ephemeral = true,
	}
end

local function createDialog(fn: function(Dialog)): function(): NilFrame
	return function(): NilFrame
		local d <const> = defaultDialog()
		d:ensureBuf()
		d:ensureWin():setOption("wrap", false)
		return z.async(fn, d) as NilFrame
	end
end

local function createAccordionForEachSet(cb: function(string, {Spec}): menu.Accordion.Item): menu.Accordion
	local items <const> = {}
	for _, s in ipairs(set.list()) do
		local pkgs <const> = set.load(s)
		table.sort(pkgs, setCmp)
		table.insert(items, (cb(s, pkgs)))
	end

	local world <const> = set.getWorld()
	table.sort(world, setCmp)
	table.insert(items, (cb("@World", world)))

	return menu.new.accordion(items)
end

actions.view = function(): NilFrame
	local m <const> = createAccordionForEachSet(function(title: string, pkgs: {Spec}): menu.Accordion.Item
		local names <const> = {}
		for i, spec in ipairs(pkgs) do
			names[i] = { spec:title() }
		end
		return {title, names}
	end)
	return z.async(m, defaultDialog()) as NilFrame
end

local function chooseAndLoadSet(d: Dialog): {Spec}, string
	local sets <const> = set.list()
	table.insert(sets, "@World")
	table.sort(sets)

	local loaded, name: {Spec}, string
	local items <const> = {}
	for i, v in ipairs(sets) do
		items[i] = { v, function()
			loaded = set.load(v)
			name = v
		end }
	end

	menu.new.accordion(items)(d, { persist = true })
	if not loaded then
		-- TODO: azync.cancel()?
		coroutine.yield()
	end
	return loaded, name
end

local function prompt(d: Dialog, promptText: string): string
	local f <const> = z.currentFrame()
	local val: string
	d:setPrompt(promptText, function(s: string)
		val = s
		d:unsetPrompt()
		vim.schedule(function()
			z.resume(f)
		end)
	end)
	z.suspend()
	return val
end

-- local function yesOrNo(d: Dialog, pre: string, affirm: string, deny: string): boolean
	-- local result: boolean
	-- menu.new.accordion{
		-- pre,
		-- { affirm or "Yes", function() result = true end },
		-- { deny or "No", function() result = false end },
	-- }(d, { persist = true })
	-- if result == nil then
		-- coroutine.yield()
	-- end
	-- return result
-- end

local function checklist(d: Dialog, pre: string, opts: {string}): {integer}
	local items <const>: {menu.Checklist.Item} = { pre }
	for i, v in ipairs(opts) do
		items[i + 1] = { v, false }
	end
	menu.new.checklist(items)(d)
	local selected <const> = {}
	for i = 2, #items do
		if (items[i] as {string, boolean})[2] then
			table.insert(selected, i - 1)
		end
	end
	return selected
end

do
	local type PackageAdder = function(d: Dialog, s: {Spec})
	local function getPkgNames(s: {Spec}): {string}
		local pkgNames <const> = {}
		for i, v in ipairs(s) do
			pkgNames[i] = v:title()
		end
		return pkgNames
	end

	local function askForDependents(d: Dialog, s: {Spec}, p: Spec)
		local deps <const> = checklist(d, "Dependents:", getPkgNames(s))
		for _, idx in ipairs(deps) do
			table.insert(p.dependents, s[idx])
		end
	end

	local function askForDependencies(d: Dialog, s: {Spec}, p: Spec)
		local deps <const> = checklist(d, "Dependencies:", getPkgNames(s))
		for _, idx in ipairs(deps) do
			if not s[idx].dependents then
				s[idx].dependents = {}
			end
			table.insert(s[idx].dependents, p)
		end
	end

	local addVimPlugPackage <const>: PackageAdder = function(_d: Dialog, _s: {Spec})
		print("Vim Plug Package: not yet implemented")
	end

	local addPackerPackage <const>: PackageAdder = function(_d: Dialog, _s: {Spec})
		print("Packer Package: not yet implemented")
	end

	local addGithubPackage <const>: PackageAdder = function(d: Dialog, s: {Spec})
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
	local function addLuaRock(_d: Dialog, _s: {Spec})
		print("TODO: add lua rock :D")
	end

	actions.add = createDialog(function(d: Dialog)
		local loaded <const>, name <const> = chooseAndLoadSet(d)

		set.save("." .. name .. "__bak", loaded)

		local function wrap(fn: PackageAdder): function()
			return function() fn(d, loaded) end
		end

		menu.new.accordion{
			"Add new package from:",
			{ "Github", wrap(addGithubPackage) },
			{ "Local directory", wrap(addLocalPackage) },
			{ "Vim-Plug expression", wrap(addVimPlugPackage) },
			{ "Packer expression", wrap(addPackerPackage) },
			{ "Lua rock", wrap(addLuaRock) },
		}(d, { persist = true })

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

-- local scheduleWrap <const> = vim.schedule_wrap
	-- as function<Args..., Rets...>(function(Args): Rets): function(Args)

local function runCmdForEachPkg(d: Dialog, getcmd: (function(Spec): {string}), loaded: {Spec}): z.Frame<nil>
	local mainTask: z.Frame<nil>

	local jobqueue <const> = {}
	local running = 0

	local menuItems <const> = {}
	local acc <const> = menu.new.accordion(menuItems)

	local redraw <const> = vim.schedule_wrap(function()
		if d:win():isValid() and acc.redraw then
			acc.redraw()
		end
	end)

	for i, pkg in ipairs(loaded) do
		local cmd <const> = getcmd(pkg)
		local title <const> = pkg:title()
		local item <const>: menu.Accordion.Item = { pkg:title() }
		menuItems[i] = item
		if cmd then
			local out <const>: {string} = {}
			local err <const>: {string} = {}
			;(item as {{{string, {string}}}})[2] = { { "stdout", out }, { "stderr", err } }
			table.insert(menuItems, item)

			table.insert(jobqueue, function()
				running = running + 1
				;(item as {string})[1] = title .. " : Working..."
				command.spawn{
					command = cmd,
					onStdoutLine = function(ln: string)
						table.insert(out, ln)
						redraw()
					end,
					onStderrLine = function(ln: string)
						table.insert(err, ln)
						redraw()
					end,
					onExit = function(code: integer)
						running = running - 1
						if code == 0 then
							;(item as {string})[1] = title .. " : Done!"
						else
							;(item as {string})[1] = title .. " : Error! (" .. tostring(code) .. ")"
						end
						redraw()
						z.resume(mainTask)
					end,
				}
			end)
		else
			;(item as {string})[1] = (item as {string})[1] .. " : Nothing to be done"
		end
	end

	local function spawnJob()
		assert(table.remove(jobqueue, math.random(1, #jobqueue)))()
	end

	return z.async(function(): nil
		mainTask = z.currentFrame() as z.Frame<nil>
		z.async(acc, d)
		while next(jobqueue) or running > 0 do
			while running < actions.maxConcurrentJobs and next(jobqueue) do
				spawnJob()
			end
			z.suspend()
		end
		assert(running == 0, "mainTask finished with jobs still running")
		assert(not next(jobqueue), "mainTask finished with jobs still queued")
	end)
end

-- local function dummyUpdateCmd(p: Spec): {string}
	-- local cmd <const> = {}
	-- for i = 1, 10 do
		-- table.insert(cmd, "echo " .. ("="):rep(i))
		-- table.insert(cmd, "sleep " .. math.random(0.05, 1))
	-- end
	-- if math.random() < .1 then
		-- local exitcode = math.random(1, 100)
		-- table.insert(cmd, "echo 'exiting with code " .. exitcode .. "' 1>&2")
		-- table.insert(cmd, "exit " .. exitcode)
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
	input.waitForKey(d:buf(), "n", "<cr>")
	local ln <const> = d:getCursor()
	local selected <const> = loaded[ln]

	if selected.dependents and next(selected.dependents) then
		local lns <const> = { "Selected package: " .. selected:title() .. " is a dependency for:" }
		for _, p in ipairs(selected.dependents) do
			table.insert(lns, "   " .. assert(p is Spec and p):title())
		end
		d:setLines(lns)
		input.waitForKey(d:buf(), "n", "<cr>")
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

	input.waitForKey(d:buf(), "n", "<cr>")
	d:close()
end)

actions.update = createDialog(function(d: Dialog)
	local loaded <const> = chooseAndLoadSet(d)
	if not loaded then return end
	z.await(runCmdForEachPkg(d, Spec.updateCmd, loaded))
	-- z.await(runCmdForEachPkg(d, dummyUpdateCmd, loaded))
end)

actions.install = createDialog(function(d: Dialog)
	local loaded <const> = chooseAndLoadSet(d)
	if not loaded then return end
	z.await(runCmdForEachPkg(d, Spec.installCmd, loaded))
end)

actions.configure = createDialog(function(d: Dialog)
	local cfg <const>, err <const> = configure.load()
	if err then
		-- TODO: allow some sort of recovery
		d:setLines{ "There was an error loading your config:", err }
		input.waitForKey(d:buf(), "n", "<cr>", "<bs>")
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

	while input.waitForKey(d:buf(), "n", "<cr>", "<bs>") == "<cr>" do
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
