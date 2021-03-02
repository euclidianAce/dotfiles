
local nvim <const> = require("euclidian.lib.nvim")

local function set<T>(t: {T}): {T:boolean}
	local s = {}
	for _, v in ipairs(t) do
		s[v] = true
	end
	return s
end

local statusline <const> = { 
	higroup = "StatuslineModeText",
	_funcs: {function(number): string} = {},
}

local active <const>: {nvim.Window.Id:boolean} = {}

local modeMap <const>: {vim.Mode:{string}} = setmetatable({
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
	["?" as vim.Mode] = {" ???? ", "Error"},
}, {
	__index = function(self: {vim.Mode:{string}}, key: vim.Mode): {string}
		return rawget(self, string.sub(key, 1, 1) as vim.Mode) or self["?" as vim.Mode]
	end
})

local userModes <const>: {string:{string}} = setmetatable({}, {
	__index = function(self: {string:{string}}, key: string): {string}
		return rawget(self, string.sub(key, 1, 1)) or modeMap[key as vim.Mode]
	end
})

function statusline.mode(mode: string, text: string, hlgroup: string)
	userModes[mode] = {text, hlgroup}
end

function statusline.getModeText(): string
	local m = vim.fn.mode(true) as vim.Mode
	local map <const> = userModes[m]
	nvim.command("hi! clear StatuslineModeText")
	nvim.command("hi! link StatuslineModeText %s", map[2])
	return map[1]
end

local record Component
	isFunc: boolean
	funcId: number
	hiGroup: string
	text: string
	tags: {string:boolean}
	invertedTags: {string:boolean}
end

local lineComponents <const>: {Component} = {}
local currentTags <const>: {string:boolean} = {}

function statusline.add(tags: {string}, invertedTags: {string}, text: (string | function(number): (string)), hiGroup: string)
	local comp: Component = {
		tags = set(tags),
		invertedTags = set(invertedTags)
	}
	comp.hiGroup = hiGroup
	if text is string then
		comp.text = text
	elseif text is function(number): string then
		statusline._funcs[#lineComponents + 1] = text
		comp.isFunc = true
		comp.funcId = #lineComponents + 1
	end
	table.insert(lineComponents, comp)
end

local function makeLine(tags: {string}, winId: number): string
	local tagSet = set(tags)
	local buf = {}
	for i, component in ipairs(lineComponents) do
		local include = false
		for t in pairs(component.tags) do
			if tagSet[t] or currentTags[t] then
				include = true
				break
			end
		end
		if include then
			for t in pairs(component.invertedTags) do
				if tagSet[t] or currentTags[t] then
					include = false
					break
				end
			end
		end
		if include then
			table.insert(buf, ("%%#%s#"):format(component.hiGroup))
			if component.isFunc then
				table.insert(
					buf,
					([[%%{luaeval("require'euclidian.lib.statusline'._funcs[%d](%d)")}]])
						:format(component.funcId, winId))
			else
				table.insert(buf, component.text)
			end
			if i < #lineComponents then
				table.insert(buf, "%#Normal#")
			end
		end
	end
	return table.concat(buf)
end

local function setLine(winId: number)
	local win <const> = nvim.Window(winId)
	local tags <const> = active[win.id]
		and {"Active"}
		or {"Inactive"}
	win:setOption("statusline", makeLine(tags, win.id))
end

function statusline.updateWindows()
	for _, winId in ipairs(vim.api.nvim_list_wins()) do
		setLine(winId)
	end
end

function statusline.setInactive(winId: number)
	winId = winId or nvim.Window().id
	active[winId] = false
	statusline.updateWindows()
end

function statusline.setActive(winId: number)
	winId = winId or nvim.Window().id
	active[winId] = true
	statusline.updateWindows()
end

function statusline.toggleTag(name: string | {string})
	if name is string then
		currentTags[name] = not currentTags[name]
	else
		for _, v in ipairs(name) do
			currentTags[v] = not currentTags[v]
		end
	end
	statusline.updateWindows()
end

function statusline.isActive(winId: number): boolean
	winId = winId or nvim.Window().id
	return active[winId]
end

nvim.augroup("Statusline", {
	{ { "WinEnter", "BufWinEnter" }, "*", statusline.setActive },
	{ "WinLeave", "*", statusline.setInactive },
})

statusline.setActive()
statusline.updateWindows()

return statusline

