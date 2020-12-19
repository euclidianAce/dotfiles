
local Package <const> = require("euclidian.lib.package-manager.Package")
local cmd <const> = require("euclidian.lib.package-manager.cmd")
local dialog <const> = require("euclidian.lib.package-manager.dialog")
local ev <const> = require("euclidian.lib.ev")
local installer <const> = require("euclidian.lib.package-manager.installer")
local set <const> = require("euclidian.lib.package-manager.set")
local window <const> = require("euclidian.lib.window")

local Dialog <const> = dialog.Dialog
local a <const> = vim.api

local interface <const> = {}
local currentDialog: thread

local function stateMachine(initialState: string, states: {string:(function(): string)})
	local currentState = initialState
	repeat currentState = states[currentState]()
	until not (currentState and states[currentState])
end

local function startDialog(f: function(dialog.Dialog))
	currentDialog = coroutine.create(function()
		local d <const> = dialog.new()
		f(d)
		d:close()
		currentDialog = nil
	end)
	coroutine.resume(currentDialog)
end

local function getResult(): string
	return coroutine.yield() as string
end

-- helper for selecting from a menu where certain lines are not an option
local function choice(d: Dialog, exclude: {number}): string
	local excludeSet = {}
	for i, v in ipairs(exclude or {}) do
		excludeSet[v] = true
	end
	local row: number
	repeat
		coroutine.yield()
		row = d:getCursor()
	until not excludeSet[row]
	return d:getLine(row)
end

local checkKey <const> = "c"
local checkStr <const> = "[%s] %s"
local function checklist(d: Dialog, title: {string}, options: {string}): {number}|string
	local titleLen = #title
	local txt: {string} = vim.tbl_map(function(s: string): string
		return "[ ] " .. s
	end, options)
	local function setTxt()
		local t = {}
		for _, v in ipairs(title) do
			table.insert(t, v)
		end
		for _, v in ipairs(txt) do
			table.insert(t, v)
		end
		d:setTxt(t)
	end
	setTxt()
	d:addKeymap("n", checkKey, "select")
	local res = getResult()
	while res == "select" do
		local idx <const> = d:getCursor() - titleLen
		if idx > 0 then
			local checked <const>, opt <const> = txt[idx]:match("^%[(.)%] (.*)$")
			txt[idx] = checkStr:format(checked == "*" and " " or "*", opt)
			setTxt()
		end
		res = getResult()
	end
	d:delKeymap("n", checkKey)
	if res == "next" then
		local ret = {}
		for i, ln in ipairs(txt) do
			if ln:match("^%[%*%]") then
				table.insert(ret, i)
			end
		end
		return ret
	end
	return res
end

local function getTitle(p: Package.Spec): string
	if p.kind == "git" then
		if p.branch then
			return p.repo .. " (branch: " .. p.branch .. ")"
		end
		return p.repo
	elseif p.kind == "local" then
		return p.path
	end
end

function interface.addPackage()
	startDialog(function(dialog: Dialog)
		dialog:setWin{ row = 5, col = 5, wid = 50, hei = 30 }
		local p: Package.Spec = {}

		local txt: {string} = {}
		local selectedSet: {Package.Spec}
		local selectedName: string

		dialog:addKeymap("n", "<cr>", "next")
		stateMachine("set", {
			set = function(): string
				local sets <const> = set.list()
				table.insert(sets, 1, "Choose a set to add the package to:")
				dialog:setTxt(sets)
				coroutine.yield()
				local row = dialog:getCursor()
				selectedName = dialog:getLine(row)
				selectedSet = set.load(selectedName)
				return "kind"
			end,
			kind = function(): string
				for kind in pairs(Package.kinds) do
					table.insert(txt, kind)
				end
				table.sort(txt)
				dialog:setTxt(txt)

				coroutine.yield()
				local row = dialog:getCursor()

				p.kind = dialog:getLine(row) as Package.Kind
				return "name"
			end,
			name = function(): string
				-- get relevant info
				-- filepath for local, repo url for git, etc.

				-- TODO: use a prompt buffer, but maybe wait for neovim to make a better api?
				local key: string
				if p.kind == "git" then
					txt = { "Repo name:", "" }
					key = "repo"
				elseif p.kind == "local" then
					txt = { "File path:", "" }
					key = "path"
				end

				dialog:setTxt(txt)
				      :setCursor(2, 0)
				      :setBufOpt("modifiable", true)
				      :addKeymap("i", "<cr>", "next")
				a.nvim_command("startinsert")

				local res <const> = getResult()
				dialog:delKeymap("i", "<cr>")
				if res == "back" then
					return "kind"
				end
				local name <const> = dialog:getLine(2)
				if #name > 0 then
					(p as table)[key] = name
					a.nvim_feedkeys("", "i", true)
					dialog:setBufOpt("modifiable", false)
					return "dependents"
				end
				return "name"
			end,
			dependents = function(): string
				dialog:setTxt{
					("Do any packages depend on '%s'?"):format(getTitle(p)),
					"Yes", "No",
				}
				dialog:setCursor(3, 0)
				local res <const> = choice(dialog)
				if res == "Yes" then
					local opts <const> = {}
					for _, p in ipairs(selectedSet) do
						table.insert(opts, getTitle(p))
					end
					-- make a checklist of packages from the Set
					local deps = checklist(dialog, {
						("Select packages that are dependent on '%s' (from %s):"):format(getTitle(p), selectedName)
					}, opts)
					if deps is {number} and #deps > 0 then
						p.dependents = {}
						for _, idx in ipairs(deps) do
							table.insert(p.dependents as {Package.Spec}, selectedSet[idx])
						end
					end
				end
				return "dependencies"
			end,
			dependencies = function(): string
				dialog:setTxt{
					("Does '%s' depend on any other packages?"):format(getTitle(p)),
					"Yes", "No",
				}:setCursor(3, 0)
				local res <const> = choice(dialog)
				if res == "Yes" then
					local opts <const> = {}
					for _, p in ipairs(selectedSet) do
						table.insert(opts, getTitle(p))
					end
					local deps <const> = checklist(dialog, {
						("Select packages that '%s' depends on (from %s):"):format(getTitle(p), selectedName)
					}, opts)
					if deps is {number} and #deps > 0 then
						for _, idx in ipairs(deps) do
							if not selectedSet[idx].dependents then
								selectedSet[idx].dependents = {}
							end
							table.insert(selectedSet[idx].dependents, p)
						end
					end
				end
				return "done"
			end,
			done = function(): string
				dialog:setTxt{ ("Package '%s' Added to set %s"):format(getTitle(p), selectedName) }
				table.insert(selectedSet, p)
				set.save(selectedName, selectedSet)
				coroutine.yield()
				return
			end,
		})
	end)
end

local function displaySet(setName: string): {string}
	local chosenSet <const> = set.load(setName)

	table.sort(
		chosenSet,
		function(p1: Package.Spec, p2: Package.Spec): boolean
			return getTitle(p1) < getTitle(p2)
		end
	)

	local txt: {string} = {}
	local function insertPkg(p: Package.Spec)
		table.insert(txt, getTitle(p))
		if p.dependents then
			table.insert(txt, "   Dependency for:")
			for i, dep in ipairs(p.dependents) do
				table.insert(txt, "      " .. getTitle(dep as Package.Spec))
			end
		end
	end
	for _, p in ipairs(chosenSet) do
		insertPkg(p)
	end

	return txt
end

local record UI
	width: number
	height: number
end

local function getUi(): UI
	return a.nvim_list_uis() as {UI} [1]
end

function interface.viewSets()
	local ui <const> = getUi()
	startDialog(function(dialog: Dialog)

		dialog:setWin{
			row = 3, col = 3,
			wid = ui.width - 6, hei = ui.height - 6,
		}

		dialog:addKeymap("n", "<cr>", "next")
		dialog:addKeymap("n", "<bs>", "back")

		local setMenu = vim.tbl_map(function(s: string): string
			return "   " .. s
		end, set.list())
		if #setMenu == 0 then
			dialog:setTxt{"No sets found"}
			return
		end
		table.insert(setMenu, 1, "Sets:")
		local function displayMenu()
			dialog:setTxt(setMenu)
		end

		stateMachine("main", {
			main = function(): string
				displayMenu()
				local res = getResult()
				if res == "back" then
					return nil
				elseif res == "next" then
					local row = dialog:getCursor()
					if row > 1 then
						local setName <const> = dialog:getLine(row)
						dialog:setTxt(displaySet(setName:match("^%s+(.+)$")))
						return "submenu"
					end
				end
			end,
			submenu = function(): string
				local res = getResult()
				if res == "back" then
					return "main"
				end
				return "submenu"
			end,
		})
	end)
end

function interface.installSet(set: {Package.Spec})
	local ui <const> = getUi()
	local d <const> = dialog.new()
	d:setWin{
		row = 3, col = 3,
		wid = ui.width - 6, hei = ui.height - 6,
	}
	local maxConcurrent <const> = 4
	local currentRunning = 0
	local queue <const> = {}
	for i, p in ipairs(set) do
		queue[i] = function()
			ev.worker(function()
				installer.installPackage(p)
			end)
		end
	end
	cmd.wrapAsync(100, function()
		ev.worker(function()
			while #queue > 0 do
				ev.waitUntil(function(): boolean
					return currentRunning < maxConcurrent
				end)
				local t <const> = table.remove(queue)
				t()
				currentRunning = currentRunning + 1
			end
		end)

		-- ev.worker(function()
			-- while #queue > 0 do
				-- d:setTxt{}
				-- ev.wait()
			-- end
		-- end)

		for name, kind, data in ev.poll do

		end
	end)
end

function interface.advanceDialog(data: any)
	assert(coroutine.resume(currentDialog, data))
end

return interface

