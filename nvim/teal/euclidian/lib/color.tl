
local util = require("euclidian.lib.util")

local record c
	type Color = [number, number, string]
	record scheme
		hi: {string:Color}
		groups: function(): (function(): string, number, number, string)
	end
end
local Color = c.Color

c.scheme.hi = {}

local function tiFmt(t: {string}, fmt: string, ...: any)
	table.insert(t, string.format(fmt, ...))
end
local function updateHiGroup(group: string, fg: number, bg: number, ex: string)
	local out = { "hi", group }
	if fg then tiFmt(out, "guifg=#%06x", fg)
	else       tiFmt(out, "guifg=none") end
	if bg then tiFmt(out, "guibg=#%06x", bg)
	else       tiFmt(out, "guibg=none") end
	if ex then tiFmt(out, "gui=%s", ex)
	else       tiFmt(out, "gui=none")   end
	util.cmdf(table.concat(out, " "))
end

local groups: {Color:string} = {}
local actualHi: {string:Color} = {}

setmetatable(c.scheme.hi, {
	__index = function(self: {string:Color}, key: string): Color
		return actualHi[key]
	end,
	__newindex = function(self: {string:Color}, key: string, val: Color)
		if groups[val] then
			-- just link the group
			util.cmdf("hi clear %s", key)
			util.cmdf("hi link %s %s", key, groups[val])
			actualHi[key] = setmetatable({}, { __index = val })
		else
			-- new group
			actualHi[key] = val
			groups[val] = key
			updateHiGroup(key, val[1], val[2], val[3])
		end
	end,
})

function c.scheme.groups(): function(): (string, number, number, string)
	return coroutine.wrap(function()
		for k, v in pairs(actualHi) do
			coroutine.yield(k, v[1], v[2], v[3])
		end
	end) as function(): (string, number, number, string)
end

return c

