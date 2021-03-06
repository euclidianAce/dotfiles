
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
	_funcs: {function(integer): string} = {},
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
}, {
	__index = function(self: {vim.Mode:{string}}, key: vim.Mode): {string}
		return rawget(self, string.sub(key, 1, 1) as vim.Mode) or { " ???? ", "Error" }
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
	local m <const> = vim.api.nvim_get_mode().mode as string
	local map <const> = userModes[m]
	nvim.command("hi! clear StatuslineModeText")
	nvim.command("hi! link StatuslineModeText %s", map[2])
	return map[1]
end

local record Component
	isFunc: boolean
	funcId: integer
	preEval: boolean
	hiGroup: string
	text: string
	tags: {string:boolean}
	invertedTags: {string:boolean}
end

local lineComponents <const>: {Component} = {}
local currentTags <const>: {string:boolean} = {}

function statusline.add(
	tags: {string},
	invertedTags: {string},
	text: (string | function(integer): string),
	hiGroup: string,
	preEval: boolean
)
	local comp: Component = {
		tags = set(tags),
		invertedTags = set(invertedTags)
	}
	comp.hiGroup = hiGroup
	if text is string then
		comp.text = text
	elseif text then
		statusline._funcs[#lineComponents + 1] = text
		comp.isFunc = true
		comp.funcId = #lineComponents + 1
	end
	comp.preEval = preEval
	table.insert(lineComponents, comp)
end

local function makeLine(tags: {string}, winId: integer): string
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
				if component.preEval then
					local ok, res = pcall(statusline._funcs[component.funcId], winId)
					if ok then
						table.insert(buf, res)
					else
						table.insert(buf, "???")
					end
				else
					table.insert(
						buf,
						([[%%{luaeval("require'euclidian.lib.statusline'._funcs[%d](%d)")}]])
							:format(component.funcId, winId)
					)
				end
			else
				table.insert(buf, component.text)
			end
			if i < #lineComponents and not lineComponents[i + 1].hiGroup then
				table.insert(buf, "%#Normal#")
			end
		end
	end
	return table.concat(buf)
end

function statusline.updateWindow(winId: integer)
	local win <const> = nvim.Window(winId)
	if win:isValid() then
		local tags <const> = active[win.id]
			and {"Active"}
			or {"Inactive"}
		win:setOption("statusline", makeLine(tags, win.id))
	end
end

function statusline.updateAllWindows()
	for _, winId in ipairs(vim.api.nvim_list_wins()) do
		statusline.updateWindow(winId)
	end
end

function statusline.setInactive(winId: integer)
	winId = winId or nvim.Window().id
	active[winId] = false
	statusline.updateWindow(winId)
end

function statusline.setActive(winId: integer)
	winId = winId or nvim.Window().id
	active[winId] = true
	statusline.updateWindow(winId)
end

function statusline.toggleTag(name: string | {string})
	-- TODO: `is` should tell the compiler the var is non-nil if the rhs is not `nil`
	for _, v in ipairs(name is {string} and assert(name) or {name}) do
		currentTags[v] = not currentTags[v]
	end
	statusline.updateAllWindows()
end

function statusline.tagToggler(name: string | {string}): function()
	return function() statusline.toggleTag(name) end
end

function statusline.isActive(winId: integer): boolean
	winId = winId or nvim.Window().id
	return active[winId]
end

nvim.augroup("Statusline", {
	{ { "WinEnter", "BufWinEnter" }, "*", statusline.setActive },
	{ "WinLeave", "*", statusline.setInactive },
})

statusline.setActive()
statusline.updateAllWindows()

return statusline
