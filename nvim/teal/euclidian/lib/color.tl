local nvim <const> = require("euclidian.lib.nvim")

local type Color = {integer, integer, string}
local enum ColorName
	"fg"
	"bg"
	"gray"
	"red"
	"green"
	"yellow"
	"blue"
	"purple"
	"orange"
	"cyan"
	"magenta"
end
local type Palette = {ColorName:integer}
local type Gradient = {integer, integer, integer}

local color <const> = {
	Color = Color,
	ColorName = ColorName,
	Palette = Palette,
	Gradient = Gradient,
	scheme = {
		hi: {string:Color} = {},
		groups: function(): (function(): string, integer, integer, string) = nil,
	},
}

local function setHl(group: string, opts: {string:any})
	nvim.api.setHl(0, group, opts)
end

local function updateHiGroup(group: string, fg: integer, bg: integer, ex: string)
	local opts <const>: {string:any} = { fg = fg, bg = bg }
	if ex then
		for k in ex:gmatch("[^,]+") do
			opts[k] = true
		end
	end
	setHl(group, opts)
end

-- TODO: should probably just use nvim_get_hl_by_name rather than caching this
local groups <const>: {Color:string} = {}
local actualHi <const>: {string:Color} = {}

setmetatable(color.scheme.hi, {
	__index = function(_self: {string:Color}, key: string): Color
		return actualHi[key]
	end,
	__newindex = function(_self: {string:Color}, key: string, val: Color)
		if not val then
			setHl(key, { link = "NONE" })
			actualHi[key] = nil
		elseif groups[val] and key ~= groups[val] then
			-- just link the group
			setHl(key, { link = groups[val] })
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
