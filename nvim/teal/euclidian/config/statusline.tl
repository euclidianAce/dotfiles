
local command <const> = require("euclidian.lib.command")
local nvim <const> = require("euclidian.lib.nvim")
local stl <const> = require("euclidian.lib.statusline")
local tu <const> = require("euclidian.lib.textutils")

stl.mode("n", "Normal", "STLNormal")
stl.mode("i", "Insert", "STLInsert")
stl.mode("c", "Command", "STLCommand")
stl.mode("r", "Confirm", "STLCommand")
stl.mode("R", "Replace", "STLReplace")
stl.mode("t", "Terminal", "STLTerminal")
stl.mode("v", "Visual", "STLVisual")
stl.mode("V", "V·Line", "STLVisual")
stl.mode("", "V·Block", "STLVisual")

local alwaysActive <const> = {"Active", "Inactive"}
local active <const> = {"Active"}
local inactive <const> = {"Inactive"}
local empty <const> = {}

stl.add(alwaysActive, empty, function(winid: integer): string
	local win <const> = nvim.Window(winid)
	-- make buffer number section line up with line number column
	local spaces <const> = win:getOption("numberwidth")
		+ tonumber(win:getOption("signcolumn"):match("yes:(%d+)")) as integer or 0
	return tu.rightAlign(tostring(win:getBuf()), spaces) .. " "
end, "STLBufferInfo", true)

stl.add(active, inactive, function(): string
	return " " .. stl.getModeText() .. " "
end, stl.higroup)

do -- git stuffs
	local gitActive <const>, gitInactive <const> = {"Git"}, {"Inactive"}
	local maxBranchWid <const> = 20
	local currentBranch = ""

	local function parseDiff(s: string): string, string, string
		-- ex: 1 file changed, 1 insertion(+)
		-- ex: 5 files changed, 98 insertions(+), 45 deletions(-)
		local ns = {}
		for n in s:gmatch("%d+") do
			table.insert(ns, n)
		end
		return unpack(ns, 1, 3)
	end

	local filesChanged, insertions, deletions: string, string, string
	nvim.autocmd("VimEnter,BufWritePost", "*", function()
		local b = nvim.Buffer()
		if b:getOption("buftype") == "nofile" then
			return
		end
		local function oneshot<T...>(fn: function(T)): function(T)
			local execd = false
			return function(...: T)
				if not execd then
					fn(...)
					execd = true
				end
			end
		end
		do
			local gotDiff = false
			command.spawn{
				command = { "git", "diff", "--shortstat" },
				cwd = vim.loop.cwd(),
				onStdoutLine = oneshot(function(ln: string)
					gotDiff = true
					filesChanged, insertions, deletions = parseDiff(ln)
					vim.schedule(stl.updateWindow)
				end),
				onExit = function()
					if not gotDiff then
						filesChanged, insertions, deletions = nil, nil, nil
						vim.schedule(stl.updateWindow)
					end
				end,
			}
		end
		command.spawn{
			command = { "git", "branch", "--show-current" },
			cwd = vim.loop.cwd(),
			onStdoutLine = oneshot(function(ln: string)
				currentBranch = ln
				vim.schedule(stl.updateWindow)
			end),
		}
	end)

	stl.add(gitActive, gitInactive, function(): string
		if currentBranch == "" then return "" end
		return " " .. currentBranch:sub(1, maxBranchWid)
	end, "STLGit", true)
	stl.add(gitActive, gitInactive, function(): string
		if currentBranch == "" then return "" end
		return (" ~%s +%s -%s "):format(filesChanged or "0", insertions or "0", deletions or "0")
	end, "STLGit", true)

	stl.toggleTag("Git")
	nvim.setKeymap("n", "<F12>", stl.tagToggler("Git"), { noremap = true })
end

stl.add(alwaysActive, empty, function(winid: integer): string
	local buf <const> = nvim.Buffer(nvim.Window(winid):getBuf())
	if buf:getOption("buftype") == "terminal" then
		return ""
	end
	return " %f %m%r%h%w"
end, "STLFname", true)

stl.add(active, inactive, " %= ", "StatusLine")
stl.add(inactive, active, " %= ", "StatusLineNC")

local insFmt <const> = tu.insertFormatted
local minWid <const> = 100
stl.add(alwaysActive, empty, function(winid: integer): string
	local win <const> = nvim.Window(winid)
	local buf <const> = nvim.Buffer(win:getBuf())

	local wid <const> = win:getWidth()
	local pos <const> = win:getCursor()

	local out <const>: {string} = {}

	if stl.isActive(winid) then
		-- tabs/spaces info
		if wid > minWid then
			local expandtab <const> = buf:getOption("expandtab")
			local num <const> = expandtab
				and buf:getOption("shiftwidth")
				or buf:getOption("tabstop")
			insFmt(out, "%s (%d)", expandtab and "spaces" or "tabs", num)
		end

		-- line info
		local totalLines <const> = #buf:getLines(0, -1, false)
		if wid > minWid then
			insFmt(out, "Ln: %3d of %3d", pos[1], totalLines)
			insFmt(out, "Col: %3d", pos[2] + 1)
			insFmt(out, "%3d%%", pos[1] / totalLines * 100)
		else
			insFmt(out, "Ln:%d C:%d", pos[1], pos[2])
		end
	else
		insFmt(out, "Ln: %3d", pos[1])
	end
	if #out > 1 then
		return "│ " .. table.concat(out, " │ ") .. "  "
	else
		return "  " .. out[1] .. "  "
	end
end, "STLBufferInfo")
