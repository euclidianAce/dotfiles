
local packagespec <const> = require("euclidian.lib.package-manager.packagespec")
local cmd <const> = require("euclidian.lib.package-manager.cmd")
local set <const> = require("euclidian.lib.package-manager.set")
local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local ev <const> = require("euclidian.lib.ev")

local a <const> = vim.api

local type Spec = packagespec.Spec
local type Dialog = dialog.Dialog

local yield <const> = coroutine.yield

local interface <const> = {
	addPackage: function() = nil,
	installSet: function() = nil,
	updateSet: function() = nil,
	showSets: function() = nil,
}

local function longest(lines: {string}): integer, string
	local idx, len = 1, #lines[1]
	for i = 2, #lines do
		if len < #lines[i] then
			len = #lines[i]
			idx = i
		end
	end
	return idx, lines[idx]
end

local floor <const>, ceil <const> = math.floor, math.ceil

local function accommodateText(d: Dialog)
	local lines <const> = d:getLines()
	local twid <const> = longest(lines)
	local thei <const> = #lines

	local col <const>, row <const>, wid <const>, hei <const> = dialog.centeredSize(twid, thei)
	d:setWin{ col = col, row = row, wid = wid, hei = hei }
end

function interface.displaySets(): Dialog
	local sets <const> = set.list()
	local _, longestSetName <const> = longest(sets)

	local d <const> = dialog.centered(#longestSetName + 3, #sets + 3)
	d:setLines(sets)

	return d
end

local currentDialog: thread

function interface._step(data: string)
	local ok, err = coroutine.resume(currentDialog, data)
	if coroutine.status(currentDialog) == "dead" then
		currentDialog = nil
	end
	if not ok then
		error(err as string)
	end
end

local function getLastLine(txt: string): string
	return txt:match("[\n]*([^\n]*)[\n]*$")
end

math.randomseed(os.time())

local stepCmd <const> = "<cmd>lua require[[euclidian.lib.package-manager.interface]]._step()<cr>"
local stepCmdFmt <const> = "<cmd>lua require[[euclidian.lib.package-manager.interface]]._step(%q)<cr>"

local function makeTitle(txt: string, width: number): string
	local chars <const> = width - #txt - 2
	return ("%s %s %s"):format(
		("="):rep(chars // 2),
		txt,
		("="):rep(ceil(chars / 2))
	)
end

local function newDialog(fn: function): function()
	return function()
		currentDialog = coroutine.create(fn)
		coroutine.resume(currentDialog)
	end
end

local function setComparator(a: Spec, b: Spec): boolean
	if not b then
		return true
	end
	if not a then
		return false
	end
	return a:title() < b:title()
end

local defaultKeymapOpts <const>: nvim.MapOpts = { silent = true, noremap = true }

local record PkgInfo
	{string}
	cwd: string
end

local function runForEachPkg(getCmd: function(Spec): PkgInfo): function()
	return newDialog(function()
		local d <const> = interface.displaySets()
		d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)
		yield()
		d:delKeymap("n", "<cr>")
		local ln <const> = d:getCursor()
		local selected <const> = d:getLine(ln)

		local textSegments <const>: {{string, string, string}} = {}

		local selectedSet <const> = set.load(selected)
		table.sort(selectedSet, setComparator)

		local maxCmds <const> = 4
		local runningCmds = 0
		local jobs <const>: {function} = {}
		local longestTitle = 0

		for i, p in ipairs(selectedSet) do
			local title <const> = p:title()
			local segment <const> = { title, "", "..." }
			if #title > longestTitle then
				longestTitle = #title
			end
			local command <const> = getCmd(p)
			if command then
				-- TODO: use buf_set_text here
				local function updateStatus(status: string)
					segment[2] = status
				end
				local function updateText(txt: string)
					segment[3] = getLastLine(txt)
				end
				local function start()
					runningCmds = runningCmds + 1
					updateStatus("started")
				end
				local function close()
					runningCmds = runningCmds - 1
					updateStatus("finished")
					if not p.post then
						return
					end
					--- TODO: this is janky, the set should be reloaded before
					--- so that any functions that need to be can be sourced
					-- updateStatus("post...")
					-- updateText("Running post install hooks...")
					-- table.insert(jobs, function()
					-- 	vim.schedule(function()
					-- 		a.nvim_exec(p.post, false)
					-- 		updateStatus("finished")
					-- 	end)
					-- end)
				end
				table.insert(jobs, function(t: thread)
					cmd.runEvented{
						command = command,
						cwd = command.cwd,
						on = {
							start = start,
							close = close,
							stdout = updateText,
							stderr = updateText,
						},
						thread = t,
					}
				end)
			else
				segment[2] = "installed"
			end
			textSegments[i+1] = segment
		end

		local ui <const> = nvim.ui()
		local width <const> = floor(ui.width * .9)
		d:center(width, #textSegments + 1)
		textSegments[1] = {
			makeTitle("Package", longestTitle),
			makeTitle("Status", 10),
			makeTitle("Output", width - longestTitle - 18),
		}
		textSegments[#textSegments+1] = textSegments[1]

		local lines <const>: {string} = {}
		local fmtStr <const> = " %" .. tostring(longestTitle) .. "s | %10s | %s"
		local function updateText()
			for i, segment in ipairs(textSegments) do
				lines[i] = fmtStr:format(segment[1], segment[2], segment[3])
			end
			d:setLines(lines)
		end
		updateText()
		local function jobsLeft(): boolean
			return not (runningCmds == 0 and #jobs == 0)
		end

		if jobsLeft() then
			ev.loop(function()
				local t <const> = coroutine.running()
				local function startJobs()
					ev.wait()
					while runningCmds < maxCmds and #jobs > 0 do
						table.remove(jobs, math.random(1, #jobs))(t)
					end
					ev.wait()
				end

				startJobs()

				while jobsLeft() do
					ev.wait()
					updateText()
					startJobs()
				end
				updateText()

				d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)
			end):asyncRun(150)
		else
			d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)
		end

		yield()
		d:close()
	end)
end

interface.showSets = newDialog(function()
	local d <const> = interface.displaySets()
	d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)
	yield()

	local ln <const> = d:getCursor()
	local selected <const> = d:getLine(ln)
	local setName = selected
	local selectedSet = set.load(selected)

	table.sort(selectedSet, setComparator)
	local txt = {
		setName,
		("="):rep(30),
	}
	for i, pkg in ipairs(selectedSet) do
		txt[i+2] = pkg:title()
	end
	d:setLines(txt)
	yield()
	d:close()
end)

interface.installSet = runForEachPkg(function(p: Spec): PkgInfo
	if not p:isInstalled() then
		return p:installCmd()
	end
end)

interface.updateSet = runForEachPkg(function(p: Spec): PkgInfo
	if p:isInstalled() then
		return { "git", "pull", cwd = p:location() }
	else
		return p:installCmd()
	end
end)

local function ask(d: Dialog, question: string, confirm: string, deny: string): boolean
	d:setCursor(1, 0)
	d:setLines{
		question,
		confirm or "Yes",
		deny or "No",
	}
	-- TODO: Only add this mapping if a <cr> mapping doesn't exist

	-- there isn't a simple way to just check if a buffer has a mapping for an lhs
	-- we can get the mappings for a buffer, but the <> parts get capitalized differently
	-- ex: <CR> vs <Cmd>
	-- Though this may not matter for the lhs? Who knows?
	d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)

	local ln: number
	repeat
		yield()
		ln = d:getCursor()
	until ln > 1

	d:delKeymap("n", "<cr>")

	return ln == 2
end

-- TODO: make this configurable
local checkKeymap <const> = "a"
local function setChecklist(d: Dialog, s: {Spec}): {Spec}
	local text <const> = {}
	for _, p in ipairs(s) do
		table.insert(text, "[ ] " .. p:title())
	end
	d:setLines(text)
	accommodateText(d)

	d:addKeymap("n", checkKeymap, stepCmdFmt:format("C"), defaultKeymapOpts)
	d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)

	while true do
		local res = yield()
		if not res then break end
		local ln <const> = d:getCursor()
		local line <const> = d:getLine(ln)
		d:setText{
			{ line:match"^%[%*" and " " or "*", ln-1, 1, ln-1, 2 },
		}
	end

	d:delKeymap("n", checkKeymap)
	local checked <const>: {Spec} = {}
	local lines <const> = d:getLines(1, -1)
	for i, line in ipairs(lines) do
		if line:match"^%[%*" then
			table.insert(checked, s[i+1])
		end
	end

	return checked
end

interface.addPackage = newDialog(function()
	local d <const> = interface.displaySets()
	d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)
	yield()

	local selectedSet: {Spec}
	local setName: string
	local newPackage: Spec = {}

	do
		local ln <const> = d:getCursor()
		local selected <const> = d:getLine(ln)
		setName = selected
		selectedSet = set.load(selected)
		table.sort(selectedSet, setComparator)

		local text <const> = {}
		for kind in pairs(packagespec.kinds) do
			table.insert(text, kind)
		end
		table.sort(text)

		d:setLines(text)
		yield()
		d:delKeymap("n", "<cr>")
	end

	do
		local ln <const> = d:getCursor()
		local selectedKind <const> = d:getLine(ln)
		newPackage.kind = selectedKind as packagespec.Kind

		d:setLines{}
		local promptText: string
		if selectedKind == "git" then
			promptText = "git repo: "
		elseif selectedKind == "local" then
			promptText = "local path: "
		end
		d:setPrompt(promptText, function(txt: string)
			if selectedKind == "git" then
				newPackage.repo = txt
			elseif selectedKind == "local" then
				newPackage.path = txt
			end

			interface._step()
		end)
		yield()
		d:unsetPrompt()
	end

	if ask(d, "Do any other installed packages depend on this package?") then
		newPackage.dependents = setChecklist(d, selectedSet)
	end

	if ask(d, "Does this package depend on any other installed packages?") then
		local dependencies <const> = setChecklist(d, selectedSet)
		for _, p in ipairs(dependencies) do
			if not p.dependents then
				p.dependents = {}
			end
			table.insert(p.dependents, newPackage)
		end
	end

	if ask(d, "Does this package have any post-install (vimscript) actions?") then
		d:addKeymap("n", "<CR>", stepCmd, defaultKeymapOpts)
		d:setLines{}
		d.buf:setOption("syntax", "vim")
		d:modify(function()
			a.nvim_command "startinsert"
			yield()
			a.nvim_command "stopinsert"
		end)
		d.buf:setOption("syntax", "")
		d.buf:setOption("modifiable", false)

		newPackage.post = table.concat(d:getLines(), "\n")
	end

	table.insert(selectedSet, newPackage)
	set.save(setName, selectedSet)

	d:setLines{ ("Saved set %s"):format(setName) }
	accommodateText(d)

	d:addKeymap("n", "<CR>", stepCmd, defaultKeymapOpts)
	yield()
	d:close()
end)

return interface

