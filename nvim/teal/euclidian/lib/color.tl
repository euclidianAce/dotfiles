
local bit <const> = require("bit")
local util <const> = require("euclidian.lib.util")
local cmdf <const> = util.nvim.cmdf

local record color
	type Color = {number, number, string}
	record scheme
		hi: {string:Color}
		groups: function(): (function(): string, number, number, string)
	end
end
color.scheme.hi = {}
local Color = color.Color

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
	cmdf(table.concat(out, " "))
end

local groups: {Color:string} = {}
local actualHi: {string:Color} = {}

setmetatable(color.scheme.hi, {
	__index = function(_self: {string:Color}, key: string): Color
		return actualHi[key]
	end,
	__newindex = function(_self: {string:Color}, key: string, val: Color)
		if not val then
			cmdf("hi link %s NONE", key)
			actualHi[key] = nil
		elseif groups[val] then
			-- just link the group
			cmdf("hi clear %s", key)
			cmdf("hi link %s %s", key, groups[val])
			actualHi[key] = setmetatable({}, { __index = val })
		else
			-- new group
			actualHi[key] = val
			groups[val] = key
			updateHiGroup(key, val[1], val[2], val[3])
		end
	end,
})

function color.scheme.groups(): function(): (string, number, number, string)
	local idx: string
	local val: Color
	return function(): (string, number, number, string)
		idx, val = next(actualHi, idx)
		if val then
			return idx, val[1], val[2], val[3]
		end
	end
end

function color.hexToRgb(hex: number): number, number, number
	return bit.rshift(hex, 16), bit.band(bit.rshift(hex, 8), 0x0000ff), bit.band(hex, 0x0000ff)
end

function color.rgbToHex(r: number, g: number, b: number): number
	return bit.bor(
		bit.lshift(r, 16),
		bit.lshift(g, 8),
		b
	)
end

return color

