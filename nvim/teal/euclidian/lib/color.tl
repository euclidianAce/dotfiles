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

function color.rgbToHsv(r: integer, g: integer, b: integer): number, number, number
	local rs <const> = r / 255
	local gs <const> = g / 255
	local bs <const> = b / 255
	local mmax <const> = math.max(rs, gs, bs)
	local mmin <const> = math.min(rs, gs, bs)
	local delta <const> = mmax - mmin

	local h: number
	if delta > 0 then
		if mmax == rs then
			h = (gs - bs) / delta
		elseif mmax == gs then
			h = (bs - rs) / delta + 2
		elseif mmax == bs then
			h = (rs - gs) / delta + 4
		end
	end

	local v <const> = mmax
	local s <const> = v == 0 and 0 or delta / v

	return h, s, v
end

--- h in [0, 6] or nil
--- s,v in [0, 1]
--- returns r,g,b in [0,1]
function color.hsvToRgb(h: number, s: number, v: number): number, number, number
	local alpha <const> = v * (1 - s)
	local beta <const> = h and v * (1 - (h - math.floor(h)) * s)
	local gamma <const> = h and v * (1 - (1 - (h - math.floor(h))) * s)

	if not h then
		return v, v, v
	end
	h = h % 6

	assert(alpha)
	assert(beta)
	assert(gamma)

	if h < 1 then
		return v, gamma, alpha
	elseif h < 2 then
		return beta, v, alpha
	elseif h < 3 then
		return alpha, v, gamma
	elseif h < 4 then
		return alpha, beta, v
	elseif h < 5 then
		return gamma, alpha, v
	elseif h < 6 then
		return v, alpha, beta
	end
	error("bad h value: h=" .. tostring(h))
end

return color
