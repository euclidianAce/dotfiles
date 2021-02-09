
local color <const> = require("euclidian.lib.color")
local p <const> = require("euclidian.config.colors")
local stl <const> = require("euclidian.lib.statusline")
local unpacker <const> = require("euclidian.lib.util").unpacker
local a <const> = vim.api

local hi <const>  = color.scheme.hi
local min <const>, max <const> = math.min, math.max
local function clamp(n: number, a: number, b: number): number
	return min(max(n, a), b)
end

local darkenFactor <const> = 2^7
local function invert(fgColor: number): color.Color
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

for m, txt, hl in unpacker{
	{ "n", "Normal", "STLNormal" },
	{ "i", "Insert", "STLInsert" },
	{ "c", "Command", "STLCommand" },
	{ "R", "Replace", "STLReplace" },
	{ "t", "Terminal", "STLTerminal" },
	{ "v", "Visual", "STLVisual" },
	{ "V", "Visual Line", "STLVisual" },
	{ "", "Visual Block", "STLVisual" },
} do
	stl.mode(m, txt, hl)
end

local alwaysActive <const> = {"Active", "Inactive"}
local active <const> = {"Active"}
local inactive <const> = {"Inactive"}
local empty <const> = {}

local ti <const> = table.insert
local sf <const> = string.format
local function tiFmt(t: {string}, fmt: string, ...: any)
	ti(t, sf(fmt, ...))
end

local winOption <const> = a.nvim_win_get_option as function(number, string): number
stl.add(alwaysActive, empty, function(winid: number): string
	local spaces <const> = winOption(winid, "numberwidth") + winOption(winid, "foldcolumn") + 1
	return (" "):rep(spaces) .. a.nvim_win_get_buf(winid) .. " "
end, "STLBufferInfo")
stl.add(active, inactive, function(): string
	return "  " .. stl.getModeText() .. " "
end, stl.higroup)
stl.add(active, inactive, function(): string
	-- [Git(branch)]
	local branch = (vim.fn.FugitiveStatusline() as string):sub(6, -3)
	if branch == "" then
		return ""
	end
	return "  * " .. branch .. " "
end, "STLGit")
local maxFileNameLen <const> = 20
stl.add(alwaysActive, empty, function(winid: number): string
	local buf <const> = a.nvim_win_get_buf(winid)
	local fname = a.nvim_buf_get_name(buf) or ""
	if fname:match("/bin/bash$") or #fname == 0 then
		return ""
	end
	local cwd <const> = vim.fn.getcwd() as string
	if fname:match("^" .. vim.pesc(cwd)) then
		fname = fname:sub(#cwd + 2, -1)
	end
	if #fname > maxFileNameLen then
		fname = " < " .. fname:sub(-maxFileNameLen, -1)
	end
	return "  " .. fname .. " "
end, "STLFname")
stl.add(alwaysActive, empty, "%m", "STLFname")
stl.add(active, inactive, "%r%h%w", "STLFname")

stl.add(active, inactive, " %= ", "StatusLine")
stl.add(inactive, active, " %= ", "StatusLineNC")

local minWid <const> = 100
stl.add(alwaysActive, empty, function(winid: number): string
	local currentBuf <const> = a.nvim_win_get_buf(winid)
	local cursorPos <const> = a.nvim_win_get_cursor(winid) as {number, number}
	local wid <const> = a.nvim_win_get_width(winid) as number
	local out: {string} = {}
	if stl.isActive(winid) then
		-- tabs/spaces info
		if wid > minWid then
			local expandtab = a.nvim_buf_get_option(currentBuf, "expandtab") as boolean
			local num: number
			if expandtab then num = a.nvim_buf_get_option(currentBuf, "shiftwidth") as number
			else              num = a.nvim_buf_get_option(currentBuf, "tabstop") as number
			end
			tiFmt(out, "%s (%d)", expandtab and "spaces" or "tabs", num)
		end

		-- line info
		local totalLines <const> = #a.nvim_buf_get_lines(currentBuf, 0, -1, false)
		if wid > minWid then
			tiFmt(out, "Ln: %3d of %3d", cursorPos[1], totalLines)
			tiFmt(out, "Col: %3d", cursorPos[2] + 1)
			tiFmt(out, "%3d%%", math.floor(cursorPos[1] / totalLines * 100))
		else
			tiFmt(out, "Ln:%d C:%d", cursorPos[1], cursorPos[2])
		end
	else
		tiFmt(out, "Ln: %3d", cursorPos[1])
	end
	if #out > 1 then
		return "│ " .. table.concat(out, " │ ") .. "  "
	else
		return "  " .. out[1] .. "  "
	end
end, "STLBufferInfo")

