
local nvim <const> = require("euclidian.lib.nvim")

local type Color = {integer, integer, string}
local color <const> = {
	Color = Color,
	scheme = {
		hi: {string:Color} = {},
		groups: function(): (function(): string, integer, integer, string) = nil,
	},
}

local function tiFmt(t: {string}, fmt: string, ...: any)
	table.insert(t, string.format(fmt, ...))
end

-- TODO: is it worth it to use nvim_set_hl? probably
local function updateHiGroup(group: string, fg: integer, bg: integer, ex: string)
	local out <const> = { "hi", group }
	if fg then
		tiFmt(out, "guifg=#%06x", fg)
	elseif fg ~= -1 then
		tiFmt(out, "guifg=none")
	end
	if bg then
		tiFmt(out, "guibg=#%06x", bg)
	elseif bg ~= -1 then
		tiFmt(out, "guibg=none")
	end
	if ex then
		tiFmt(out, "gui=%s", ex)
	elseif ex ~= "" then
		tiFmt(out, "gui=none")
	end
	nvim.command(table.concat(out, " "))
end

local groups <const>: {Color:string} = {}
local actualHi <const>: {string:Color} = {}

setmetatable(color.scheme.hi, {
	__index = function(_self: {string:Color}, key: string): Color
		return actualHi[key]
	end,
	__newindex = function(_self: {string:Color}, key: string, val: Color)
		if not val then
			nvim.command("hi link %s NONE", key)
			actualHi[key] = nil
		elseif groups[val] and key ~= groups[val] then
			-- just link the group
			nvim.command("hi clear %s", key)
			nvim.command("hi link %s %s", key, groups[val])
			actualHi[key] = setmetatable({}, { __index = val })
		else
			-- new group
			actualHi[key] = val
			groups[val] = key
			updateHiGroup(key, val[1], val[2], val[3])
		end
	end,
})

color.scheme.groups = function(): function(): (string, integer, integer, string)
	local idx: string
	local val: Color
	return function(): (string, integer, integer, string)
		idx, val = next(actualHi, idx)
		if val then
			return idx, val[1], val[2], val[3]
		end
	end
end

function color.hexToRgb(hex: integer): integer, integer, integer
	return hex >> 16, (hex >> 8) & 0xff, hex & 0xff
end

function color.rgbToHex(r: integer, g: integer, b: integer): integer
	return (r << 16) | (g << 8) | b
end

return color
