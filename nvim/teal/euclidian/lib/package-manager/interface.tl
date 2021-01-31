
local packagespec <const> = require("euclidian.lib.package-manager.packagespec")
local cmd <const> = require("euclidian.lib.package-manager.cmd")
local set <const> = require("euclidian.lib.package-manager.set")
local window <const> = require("euclidian.lib.window")
local dialog <const> = require("euclidian.lib.dialog")
local ev <const> = require("euclidian.lib.ev")

local Spec <const> = packagespec.Spec
local Dialog <const> = dialog.Dialog

local yield <const> = coroutine.yield

local interface <const> = {}

local function longest(lines: {string}): number, string
	local idx, len = 1, #lines[1]
	for i = 2, #lines do
		if len < #lines[i] then
			len = #lines[i]
			idx = i
		end
	end
	return idx, lines[idx]
end

local floor <const>, ceil <const>, max <const>, min <const>
	= math.floor, math.ceil, math.max, math.min
local function getWinSize(wid: number, hei: number): number, number, number, number
	local ui <const> = window.ui()

	local minWid <const> = floor(ui.width * .25)
	local minHei <const> = floor(ui.height * .25)

	local maxWid <const> = floor(ui.width * .90)
	local maxHei <const> = floor(ui.height * .90)

	wid = min(max(minWid, wid), maxWid)
	hei = min(max(minHei, hei), maxHei)

	return floor((ui.width - wid) / 2), floor((ui.height - hei) / 2), wid, hei
end

local function getWinSizeTable(width: number, height: number): Dialog.Opts
	local col <const>, row <const>, wid <const>, hei <const> = getWinSize(width, height)
	return { col = col, row = row, wid = wid, hei = hei }
end

local function accommodateText(d: Dialog)
	local lines <const> = d:getLines()
	local twid <const> = longest(lines)
	local thei <const> = #lines

	local col <const>, row <const>, wid <const>, hei <const> = getWinSize(twid, thei)
	d:setWin{ col = col, row = row, wid = wid, hei = hei }
end

function interface.displaySets(): Dialog
	local sets <const> = set.list()
	local _, longestSetName = longest(sets)

	local d <const> = dialog.new(getWinSize(#longestSetName + 3, #sets + 3))
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
		("="):rep(floor(chars / 2)),
		txt,
		("="):rep(ceil(chars / 2))
	)
end

local function setCurrentDialog(fn: function)
	currentDialog = coroutine.create(fn)
	coroutine.resume(currentDialog)
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

local defaultKeymapOpts <const> = { silent = true, noremap = true }

local record PkgInfo
	{string}
	cwd: string
end

local function runForEachPkg(getCmd: function(Spec): PkgInfo)
	setCurrentDialog(function()
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
				table.insert(jobs, function(t: thread)
					cmd.runEvented{
						command = command,
						cwd = command.cwd,
						on = {
							start = function()
								runningCmds = runningCmds + 1
								updateStatus("started")
							end,
							close = function()
								runningCmds = runningCmds - 1
								updateStatus("finished")
							end,
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

		local ui <const> = window.ui()
		local width <const> = floor(ui.width * .9)
		d:setWin(getWinSizeTable(width, #textSegments + 1))
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

function interface.installSet()
	runForEachPkg(function(p: Spec): PkgInfo
		if not p:isInstalled() then
			return p:installCmd()
		end
	end)
end

function interface.updateSet()
	runForEachPkg(function(p: Spec): PkgInfo
		if p:isInstalled() then
			return { "git", "pull", cwd = p:location() }
		else
			return p:installCmd()
		end
	end)
end

local function ask(d: Dialog, question: string, confirm: string, deny: string): boolean
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

function interface.addPackage()
	setCurrentDialog(function()
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

		if ask(d, "Do any other packages depend on this package?") then
			newPackage.dependents = setChecklist(d, selectedSet)
		end

		table.insert(selectedSet, newPackage)
		set.save(setName, selectedSet)

		d:setLines{ ("Saved set %s"):format(setName) }
		accommodateText(d)

		yield()
		d:close()
	end)
end

return interface

