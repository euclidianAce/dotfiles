
local color <const> = require("euclidian.lib.color")
local p <const> = require("euclidian.config.colors")
local stl <const> = require("euclidian.lib.statusline")
local unpacker <const> = require("euclidian.lib.util").unpacker
local a <const> = vim.api
local winOption <const> = a.nvim_win_get_option

local hi <const>  = color.scheme.hi
hi.STLBufferInfo  = { 0, hi.Comment[1] }
hi.STLGit         = { 0, p.darkGreen }
hi.STLFname       = { 0, p.brightGray }
hi.STLNormal      = { 0, p.blue }
hi.STLInsert      = { 0, p.green }
hi.STLCommand     = { 0, p.purple }
hi.STLReplace     = { 0, p.red }

for m, txt, hl in unpacker{
	{ "n", "Normal", "STLNormal" },
	{ "i", "Insert", "STLInsert" },
	{ "c", "Command", "STLCommand" },
	{ "r", "Replace", "STLReplace" },
} do
	stl.mode(m, txt, hl)
end

stl.add({"BufferNumber", "Active", "Inactive"}, {}, function(winId: number): string
	return (" "):rep(winOption(winId, "numberwidth") as number + winOption(winId, "foldcolumn") as number + 1)
end, "STLBufferInfo")
stl.add({"BufferNumber", "Active", "Inactive"}, {}, "%n ", "STLBufferInfo")
stl.add({"ModeText", "Active"}, {"Inactive"}, function(): string
	return " " .. stl.getModeText() .. " "
end, stl.higroup)
stl.add({"GitBranch", "Active", "Inactive"}, {"Debugging"}, function(): string
	-- [Git(branch)]
	local branch = (vim.fn.FugitiveStatusline() as string):sub(6, -3)
	if branch == "" then
		return ""
	end
	return "  * " .. branch .. " "
end, "STLGit")
local maxFileNameLen <const> = 20
stl.add({"FileName", "Active", "Inactive"}, {"Debugging"}, function(winId: number): string
	-- TODO: Nov 27 00:08 2020
	--       Use window width + some other stuff to calc max len
	local ok, buf = pcall(a.nvim_win_get_buf, winId)
	if ok and buf then
		local fname = a.nvim_buf_get_name(buf)
		if fname:match("/bin/bash$") then
			return ""
		end
		if #fname > maxFileNameLen then
			fname = fname:sub(-maxFileNameLen, -1)
		end
		return "  " .. fname .. " "
	end
	return " ??? "
end, "STLFname")
stl.add({"EditInfo", "Active", "Inactive"}, {"Debugging"}, "%m", "STLFname")
stl.add({"EditInfo", "Active"}, {"Debugging", "Inactive"}, "%r%h%w", "STLFname")

stl.add({"ActiveSeparator", "Active"}, {"Inactive"}, " %= ", "StatusLineNC")
stl.add({"InactiveSeparator", "Inactive"}, {"Active"}, " %= ", "StatusLine")
stl.add({"Shiftwidth", "Tabstop", "Expandtab", "Active"}, {"Inactive"}, function(): string
	local expandtab = a.nvim_buf_get_option(0, "expandtab")
	local num: number
	if expandtab == 1 then
		num = a.nvim_buf_get_option(0, "tabstop") as number
	else
		num = a.nvim_buf_get_option(0, "shiftwidth") as number
	end
	return ("  %s (%d) "):format(expandtab and "spaces" or "tabs", num)
end, "STLBufferInfo")
stl.add({"LineNumber", "NavInfo", "Active", "Inactive"}, {}, " %l/%L:%c ", "STLBufferInfo")
stl.add({"FilePercent", "NavInfo", "Active", "Inactive"}, {"Debugging"}, "%3p%% ", "STLBufferInfo")

