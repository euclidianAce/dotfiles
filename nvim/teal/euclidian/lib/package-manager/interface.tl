
local packagespec <const> = require("euclidian.lib.package-manager.packagespec")
local cmd <const> = require("euclidian.lib.package-manager.cmd")
local set <const> = require("euclidian.lib.package-manager.set")
local window <const> = require("euclidian.lib.window")
local dialog <const> = require("euclidian.lib.dialog")
local ev <const> = require("euclidian.lib.ev")

local Spec <const> = packagespec.Spec

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

local function getWinSize(wid: number, hei: number): number, number, number, number
	local ui <const> = window.ui()
	local minWid <const> = math.floor(ui.width / 4)
	local minHei <const> = math.floor(ui.height / 4)

	wid = math.max(minWid, wid)
	hei = math.max(minHei, hei)

	return math.floor((ui.width - wid) / 2), math.floor((ui.height - hei) / 2), wid, hei
end

local function getWinSizeTable(width: number, height: number): dialog.Dialog.Opts
	local col <const>, row <const>, wid <const>, hei <const> = getWinSize(width, height)
	return { col = col, row = row, wid = wid, hei = hei }
end

function interface.displaySets(): dialog.Dialog
	local sets <const> = set.list()
	local _, longestSetName = longest(sets)

	local d <const> = dialog.new(getWinSize(#longestSetName + 3, #sets + 3))
	d:setLines(sets)

	return d
end

local currentDialog: thread

function interface._step()
	coroutine.resume(currentDialog)
end

local function getLastLine(txt: string): string
	return txt:match("[\n]*([^\n]*)[\n]*$")
end

math.randomseed(os.time())

local stepCmd <const> = "<cmd>lua require[[euclidian.lib.package-manager.interface]]._step()<cr>"

local function makeTitle(txt: string, width: number): string
	local chars <const> = width - #txt - 2
	return ("%s %s %s"):format(
		("="):rep(math.floor(chars / 2)),
		txt,
		("="):rep(math.ceil(chars / 2))
	)
end

local function setCurrentDialog(fn: function)
	currentDialog = coroutine.create(fn)
	coroutine.resume(currentDialog)
end

local function runForEachPkg(getCmd: function(Spec): {string})
	setCurrentDialog(function()
		local d <const> = interface.displaySets()
		d:addKeymap("n", "<cr>", stepCmd, { silent = true, noremap = true })
		coroutine.yield()
		d:delKeymap("n", "<cr>")
		local ln <const> = d:getCursor()
		local selected <const> = d:getLine(ln)

		local textSegments <const>: {{3 of string}} = {}

		local selectedSet <const> = set.load(selected)
		table.sort(selectedSet, function(a: Spec, b: Spec): boolean
			return a:title() < b:title()
		end)

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
						cwd = p:location(),
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
		local width <const> = math.floor(ui.width * .9)
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

				d:addKeymap("n", "<cr>", stepCmd, { silent = true, noremap = true })
			end):asyncRun(150)
		else
			d:addKeymap("n", "<cr>", stepCmd, { silent = true, noremap = true })
		end

		coroutine.yield()
		d:close()

		currentDialog = nil
	end)
end

function interface.installSet()
	runForEachPkg(function(p: Spec): {string}
		if not p:isInstalled() then
			return p:installCmd()
		end
	end)
end

function interface.updateSet()
	runForEachPkg(function(p: Spec): {string}
		return { "echo", "git", "pull", "(" .. p:title() .. ")" }
	end)
end

return interface

