local M = {}

local cmd = vim.api.nvim_command
local function set(t)
	local s = {}
	for _, v in ipairs(t) do
		s[v] = true
	end
	return s
end


local modeMap = {
	n = {"Normal", "DraculaPurple"},
	i = {"Insert", "DraculaGreen"},
	R = {"Replace", "DraculaRed"},
	v = {"Visual", "DraculaYellow"},
	V = {"Visual Line", "DraculaYellow"},
	[""] = {"Visual Block", "DraculaYellow"},
	c = {"Command", "DraculaPink"},
	s = {"Select", "DraculaYellow"},
	S = {"Select Line", "DraculaYellow"},
	[""] = {"Select Block", "DraculaYellow"},
	t = {"Terminal", "DraculaOrange"},
}

function M.getModeText()
	local m = vim.fn.mode()
	cmd("hi! link User3 " .. modeMap[m][2])
	return modeMap[m][1]
end

local lineComponents = {}
local function addComp(tags, text, hiGroup)
	table.insert(
		lineComponents,
		{
			text = ("%%#%s#"):format(hiGroup) .. text .. "%#Normal#",
			tags = set(tags),
		}
	)
end
local function components()
	local i = 0
	return function()
		i = i + 1
		if lineComponents[i] then
			return lineComponents[i].tags, lineComponents[i].text
		end
	end
end

addComp({"LeadingSpace", "Spaces"}, " ", "Comment")
addComp({"ModeText"}, [=[[%{luaeval("require'statusline'.getModeText()")}]]=], "User3")
addComp({"BufferNumber"}, "[buf: %n]", "Comment")
addComp({"FileName"}, "[%.30f]", "Identifier")
addComp({"EditInfo"}, "%y%r%h%w%m ", "Comment")
addComp({"SyntaxViewer"}, [[ [Current Syntax Item: %{synIDattr(synID(line("."), col("."), 0), "name")}]  ]], "DraculaPurpleBold")
addComp({"ActiveSeparator"}, "%=", "User1")
addComp({"InactiveSeparator"}, "%=", "User2")
addComp({"LineNumber", "NavInfo"}, " %l/%L:%c ", "Comment")
addComp({"FilePercent", "NavInfo"}, "%3p%%", "Comment")
addComp({"TrailingSpace", "Spaces"}, " ", "Comment")

cmd "hi! User2 guibg=#1F1F1F"
cmd "hi! link User1 Visual"

local lines = {
	active = set{ "ActiveSeparator", "Spaces", "ModeText", "BufferNumber", "FileName", "EditInfo", "NavInfo" },
	inactive = set{ "InactiveSeparator", "Spaces", "BufferNumber", "FileName", "EditInfo" },
}
function M.toggleTag(name)
	lines.active[name] = not lines.active[name]
	M.setActive() -- we need to redraw the active line
end

local function makeLine(name)
	local lineTags = lines[name]
	local buf = {}
	for compTags, text in components() do
		local include = false
		for t in pairs(compTags) do
			if lineTags[t] then
				include = true
				break
			end
		end
		if include then
			table.insert(buf, text)
		end
	end
	return table.concat(buf)
end

function M.setInactive()
	vim.api.nvim_win_set_option(0, "statusline", makeLine("inactive"))
end

function M.setActive()
	vim.api.nvim_win_set_option(0, "statusline", makeLine("active"))
end

-- this feels wrong to do with just a bunch of command calls
cmd "augroup customstatus"
cmd 	"autocmd!"
cmd	"autocmd WinEnter,BufWinEnter * lua require('statusline').setActive()"
cmd	"autocmd WinLeave * lua require('statusline').setInactive()"
cmd "augroup END"
M.setActive()

return M
