local M = {}

local cmd = vim.api.nvim_command
local function set<T>(t: {T}): {T:boolean}
	local s = {}
	for _, v in ipairs(t) do
		s[v] = true
	end
	return s
end

local modeMap: {string:{string}} = {
	["n"] = {"Normal", "DraculaPurple"},
	["i"] = {"Insert", "DraculaGreen"},
	["ic"] = {"Insert", "DraculaGreenBold"},
	["ix"] = {"Insert", "DraculaGreenBold"},
	["R"] = {"Replace", "DraculaRed"},
	["v"] = {"Visual", "DraculaYellow"},
	["V"] = {"Visual Line", "DraculaYellow"},
	[""] = {"Visual Block", "DraculaYellow"},
	["c"] = {"Command", "DraculaPink"},
	["s"] = {"Select", "DraculaYellow"},
	["S"] = {"Select Line", "DraculaYellow"},
	[""] = {"Select Block", "DraculaYellow"},
	["t"] = {"Terminal", "DraculaOrange"},
	["!"] = {"Shell...", "Comment"},
}

function M.getModeText(): string
	local m: string = vim.fn.mode(true) as string
	if not modeMap[m] then
		m = m:sub(1,1)
	end
	cmd("hi! link User3 " .. modeMap[m][2])
	return modeMap[m][1]
end

local Component = record
	text: string
	tags: {string:boolean}
	invertedTags: {string:boolean}
end

local lineComponents: {Component} = {}
local currentTags: {string:boolean} = {}

local function addComp(tags: {string}, invertedTags: {string}, text: string, hiGroup: string)
	table.insert(
		lineComponents,
		{
			text = ("%%#%s#"):format(hiGroup) .. text .. "%#Normal#",
			tags = set(tags),
			invertedTags = set(invertedTags)
		}
	)
end
local function components(): function(): {string:boolean}, {string:boolean}, string
	local i = 0
	return function(): {string:boolean}, {string:boolean}, string
		i = i + 1
		if lineComponents[i] then
			return lineComponents[i].tags, lineComponents[i].invertedTags, lineComponents[i].text
		end
	end
end

local function makeLine(tags: {string}): string
	local tagSet = set(tags)
	local buf = {}
	local text: string
	for compTags, compInvTags, text in components() do
		local include = false
		for t in pairs(compTags) do
			if tagSet[t] or currentTags[t] then
				include = true
				break
			end
		end
		for t in pairs(compInvTags) do
			if tagSet[t] or currentTags[t] then
				include = false
				break
			end
		end
		if include then
			table.insert(buf, text as string)
		end
	end
	return table.concat(buf)
end

function M.setInactive()
	vim.api.nvim_win_set_option(0, "statusline", makeLine{"Inactive"})
end

function M.setActive()
	vim.api.nvim_win_set_option(0, "statusline", makeLine{"Active"})
end

function M.toggleTag(name: string)
	currentTags[name] = not currentTags[name]
	M.setActive()
end

cmd "augroup customstatus"
cmd	"autocmd!"
cmd	"autocmd WinEnter,BufWinEnter * lua require('statusline').setActive()"
cmd	"autocmd WinLeave * lua require('statusline').setInactive()"
cmd "augroup END"
M.setActive()

addComp({"LeadingSpace", "Spaces", "Active", "Inactive"}, {}, " ", "Comment")
addComp({"ModeText", "Active"}, {"Inactive"}, [=[[%{luaeval("require'statusline'.getModeText()")}]]=], "User3")
addComp({"BufferNumber", "Active", "Inactive"}, {"Debugging"}, "[buf: %n]", "Comment")
addComp({"FileName", "Active", "Inactive"}, {"Debugging"}, "[%.30f]", "Identifier")
addComp({"EditInfo", "Active", "Inactive"}, {"Debugging"}, "%y%r%h%w%m ", "Comment")
addComp({"SyntaxViewer", "Debugging"}, {"Inactive"}, [[ [Current Syntax Item: %{synIDattr(synID(line("."), col("."), 0), "name")}]  ]], "DraculaPurpleBold")
-- addComp({"IndentViewer", "Debugging"}, {"Inactive"}, [[ [Current Teal Indent: %{GetTealIndent(line(".")) / &shiftwidth}]  ]], "DraculaPurpleBold")
addComp({"ActiveSeparator", "Active"}, {"Inactive"}, "%=", "User1")
addComp({"InactiveSeparator", "Inactive"}, {"Active"}, "%=", "User2")
addComp({"LineNumber", "NavInfo", "Active", "Inactive"}, {}, " %l/%L:%c ", "Comment")
addComp({"FilePercent", "NavInfo", "Active", "Inactive"}, {"Debugging"}, "%3p%%", "Comment")
addComp({"TrailingSpace", "Spaces", "Active", "Inactive"}, {}, " ", "Comment")

cmd "hi! User2 guibg=#1F1F1F"
cmd "hi! link User1 Visual"

return M
