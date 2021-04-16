
local color <const> = require("euclidian.lib.color")
local command <const> = require("euclidian.lib.command")
local nvim <const> = require("euclidian.lib.nvim")
local p <const> = require("euclidian.config.colors")
local stl <const> = require("euclidian.lib.statusline")

local hi <const> = color.scheme.hi
local min <const>, max <const> = math.min, math.max
local function clamp<T>(n: T, a: number, b: number): T
	return min(max(n, a), b) as T
end

local darkenFactor <const> = 128
local function invert(fgColor: integer): color.Color
	local r, g, b = color.hexToRgb(fgColor)
	return {
		color.rgbToHex(
			r - clamp(darkenFactor, r * 0.16, r * 0.90),
			g - clamp(darkenFactor, g * 0.16, g * 0.90),
			b - clamp(darkenFactor, b * 0.16, b * 0.90)
		),
		fgColor
	}
end

hi.STLBufferInfo  = invert(hi.Comment[1])
hi.STLGit         = invert(p.darkGreen)
hi.STLFname       = invert(p.brightGray)
hi.STLNormal      = invert(p.blue)
hi.STLInsert      = invert(p.green)
hi.STLCommand     = invert(p.purple)
hi.STLReplace     = invert(p.red)
hi.STLVisual      = invert(p.yellow)
hi.STLTerminal    = invert(p.orange)

hi.StatusLine     = hi.STLBufferInfo
hi.StatusLineNC   = invert(p.gray)

stl.mode("n", "Normal", "STLNormal")
stl.mode("i", "Insert", "STLInsert")
stl.mode("c", "Command", "STLCommand")
stl.mode("r", "Confirm", "STLCommand")
stl.mode("R", "Replace", "STLReplace")
stl.mode("t", "Terminal", "STLTerminal")
stl.mode("v", "Visual", "STLVisual")
stl.mode("V", "Visual Line", "STLVisual")
stl.mode("", "Visual Block", "STLVisual")

local alwaysActive <const> = {"Active", "Inactive"}
local active <const> = {"Active"}
local inactive <const> = {"Inactive"}
local empty <const> = {}

local ti <const> = table.insert
local sf <const> = string.format
local function tiFmt(t: {string}, fmt: string, ...: any)
	ti(t, sf(fmt, ...))
end

stl.add(alwaysActive, empty, function(winid: integer): string
	local win <const> = nvim.Window(winid)
	local spaces <const> = win:getOption("numberwidth") + 1
	return (" "):rep(spaces) .. nvim.Window(winid):getBuf() .. " "
end, "STLBufferInfo", true)
stl.add(active, inactive, function(): string
	return " " .. stl.getModeText() .. " "
end, stl.higroup)


do -- git stuffs
	local gitActive <const>, gitInactive <const> = {"Git"}, {"Inactive"}
	local maxBranchWid <const> = 20
	local currentBranch = ""

	local function parseDiff(s: string): string, string, string
		-- ex: 5 files changed, 98 insertions(+), 45 deletions(-)
		return s:match("(%d+) files changed, (%d+) insertions%(%+%), (%d+) deletions")
	end

	local filesChanged, insertions, deletions = "0", "0", "0"
	nvim.autocmd("VimEnter,BufWritePost", "*", function()
		local b = nvim.Buffer()
		if b:getOption("buftype") == "nofile" then
			return
		end
		command.spawn{
			command = { "git", "diff", "--shortstat" },
			cwd = vim.loop.cwd(),
			onStdoutLine = function(ln: string)
				filesChanged, insertions, deletions = parseDiff(ln)
				vim.schedule(stl.updateWindow)
			end,
		}
		command.spawn{
			command = { "git", "branch", "--show-current" },
			cwd = vim.loop.cwd(),
			onStdoutLine = function(ln: string)
				currentBranch = ln
				vim.schedule(stl.updateWindow)
			end,
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
	nvim.setKeymap("n", "<F12>", function() stl.toggleTag("Git") end, {noremap = true})
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

local minWid <const> = 100
stl.add(alwaysActive, empty, function(winid: integer): string
	local win <const> = nvim.Window(winid)
	local buf <const> = nvim.Buffer(win:getBuf())

	local wid <const> = win:getWidth()
	local pos <const> = win:getCursor()

	local out: {string} = {}
	if stl.isActive(winid) then
		-- tabs/spaces info
		if wid > minWid then
			local expandtab = buf:getOption("expandtab")
			local num: integer
			if expandtab then
				num = buf:getOption("shiftwidth")
			else
				num = buf:getOption("tabstop")
			end
			tiFmt(out, "%s (%d)", expandtab and "spaces" or "tabs", num)
		end

		-- line info
		local totalLines <const> = #buf:getLines(0, -1, false)
		if wid > minWid then
			tiFmt(out, "Ln: %3d of %3d", pos[1], totalLines)
			tiFmt(out, "Col: %3d", pos[2] + 1)
			tiFmt(out, "%3d%%", pos[1] / totalLines * 100)
		else
			tiFmt(out, "Ln:%d C:%d", pos[1], pos[2])
		end
	else
		tiFmt(out, "Ln: %3d", pos[1])
	end
	if #out > 1 then
		return "│ " .. table.concat(out, " │ ") .. "  "
	else
		return "  " .. out[1] .. "  "
	end
end, "STLBufferInfo")

