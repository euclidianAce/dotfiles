
local util <const> = require("euclidian.lib.util")
local set <const> = util.set
local a <const> = vim.api

local statusline = {
	higroup = "StatuslineModeText",
	_funcs: {function(number): string} = {},
	-- flag = {
		-- column = "%c",
		-- lineNum = "%l",
		-- numLines = "%L",
		-- filePercent = "%p",
		-- sep = "%=",
		-- modified = "%m",
	-- },
}

local cmd = vim.api.nvim_command

local enum Mode
	"n" -- Normal
	"no" -- Operator-pending
	"nov" -- Operator-pending (forced charwise |o_v|)
	"noV" -- Operator-pending (forced linewise |o_V|)
	"no" -- Operator-pending (forced blockwise |o_CTRL-V|)
	"niI" -- Normal using |i_CTRL-O| in |Insert-mode|
	"niR" -- Normal using |i_CTRL-O| in |Replace-mode|
	"niV" -- Normal using |i_CTRL-O| in |Virtual-Replace-mode|
	"v" -- Visual by character
	"V" -- Visual by line
	"" -- Visual blockwise
	"s" -- Select by character
	"S" -- Select by line
	"" -- Select blockwise
	"i" -- Insert
	"ic" -- Insert mode completion |compl-generic|
	"ix" -- Insert mode |i_CTRL-X| completion
	"R" -- Replace |R|
	"Rc" -- Replace mode completion |compl-generic|
	"Rv" -- Virtual Replace |gR|
	"Rx" -- Replace mode |i_CTRL-X| completion
	"c" -- Command-line editing
	"cv" -- Vim Ex mode |gQ|
	"ce" -- Normal Ex mode |Q|
	"r" -- Hit-enter prompt
	"rm" -- The -- more -- prompt
	"r?" -- |:confirm| query of some sort
	"!" -- Shell or external command is executing
	"t" -- Terminal mode: keys go to the job

	"?" -- Handle internal errors with this
end

local modeMap: {Mode:{string}} = setmetatable({
	["n"] = {"Normal", "Constant"},
	["i"] = {"Insert", "Function"},
	["r"] = {"Confirm", "Special"},
	["R"] = {"Replace", "Special"},
	["v"] = {"Visual", "String"},
	["V"] = {"Visual Line", "String"},
	[""] = {"Visual Block", "String"},
	["c"] = {"Command", "Special"},
	["s"] = {"Select", "Visual"},
	["S"] = {"Select Line", "Visual"},
	[""] = {"Select Block", "Visual"},
	["t"] = {"Terminal", "Number"},
	["!"] = {"Shell", "Comment"},
	["?"] = {" ???? ", "Error"},
}, {
	__index = function(self: {Mode:{string}}, key: Mode): {string}
		return rawget(self, string.sub(key, 1, 1) as Mode) or self["?"]
	end
})

local userModes: {string:{string}} = setmetatable({}, {
	__index = function(self: {string:{string}}, key: string): {string}
		return rawget(self, string.sub(key, 1, 1)) or modeMap[key as Mode]
	end
})

function statusline.mode(mode: string, text: string, hlgroup: string)
	userModes[mode] = {text, hlgroup}
end

function statusline.getModeText(): string
	local m: Mode = vim.fn.mode(true) as Mode
	local map <const> = userModes[m]
	cmd("hi! clear StatuslineModeText | hi! link StatuslineModeText " .. map[2])
	return map[1]
end

local record Component
	isFunc: boolean
	text: {string}
	tags: {string:boolean}
	invertedTags: {string:boolean}
end

local lineComponents: {Component} = {}
local currentTags: {string:boolean} = {}

function statusline.add(tags: {string}, invertedTags: {string}, text: string|function(number): (string), hiGroup: string)
	local comp: Component = {
		tags = set(tags),
		invertedTags = set(invertedTags)
	}
	if text is string then
		comp.text = {
			("%%#%s#"):format(hiGroup),
			text,
			"%#Normal#"
		}
	elseif text is function(number): string then
		statusline._funcs[#lineComponents+1] = text
		comp.isFunc = true
		comp.text = {
			("%%#%s#"):format(hiGroup), ([[%%{luaeval("require'euclidian.lib.statusline'._funcs[%d](]]):format(#lineComponents+1),
			[[)")}]],
			"%#Normal#",
		}
	end
	table.insert(lineComponents, comp)
end

local function components(): function(): {string:boolean}, {string:boolean}, {string}, boolean
	local i = 0
	return function(): {string:boolean}, {string:boolean}, {string}, boolean
		i = i + 1
		if lineComponents[i] then
			return lineComponents[i].tags, lineComponents[i].invertedTags, lineComponents[i].text, lineComponents[i].isFunc
		end
	end
end

local function makeLine(tags: {string}, winId: number): string
	local tagSet = set(tags)
	local buf = {}
	for compTags, compInvTags, text, isFunc in components() do
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
			if isFunc then
				table.insert(buf, text[1])
				table.insert(buf, text[2])
				table.insert(buf, tostring(winId))
				table.insert(buf, text[3])
			else
				table.insert(buf, table.concat(text))
			end
		end
	end
	return table.concat(buf)
end

local function setLine(winId: number)
	local ok, active = pcall(vim.api.nvim_win_get_var, winId or 0, "statusline_active")
	if not ok then
		pcall(vim.api.nvim_win_set_var, winId or 0, "statusline_active", 0)
		active = 0
	end
	local tags = active == 1
		and {"Active"}
		or {"Inactive"}
	vim.api.nvim_win_set_option(winId or 0, "statusline", makeLine(tags, winId))
end

function statusline.updateWindows()
	for _, win_id in ipairs(vim.api.nvim_list_wins()) do
		setLine(win_id)
	end
end

function statusline.setInactive(win_id: number)
	vim.api.nvim_win_set_var(win_id or 0, "statusline_active", 0)
	statusline.updateWindows()
end

function statusline.setActive(win_id: number)
	vim.api.nvim_win_set_var(win_id or 0, "statusline_active", 1)
	statusline.updateWindows()
end

function statusline.toggleTag(name: string|{string})
	if name is string then
		currentTags[name] = not currentTags[name]
	else
		for _, v in ipairs(name) do
			currentTags[v] = not currentTags[v]
		end
	end
	statusline.updateWindows()
end

function statusline.isActive(winid: number): boolean
	return a.nvim_win_get_var(winid or 0, "statusline_active") == 1
end

cmd "augroup customstatus"
cmd	"autocmd!"
cmd	"autocmd WinEnter,BufWinEnter * let w:statusline_active = 1 | lua require'euclidian.lib.statusline'.updateWindows()"
cmd	"autocmd WinLeave *             let w:statusline_active = 0"
cmd "augroup END"

statusline.setActive()
statusline.updateWindows()

return statusline
