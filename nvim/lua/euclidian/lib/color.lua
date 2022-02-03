local nvim = require("euclidian.lib.nvim")

local Color = {}
local ColorName = {}












local Palette = {}
local Gradient = {}

local color = {
   Color = Color,
   ColorName = ColorName,
   Palette = Palette,
   Gradient = Gradient,
   scheme = {
      hi = {},
      groups = nil,
   },
}

local function setHl(group, opts)
   nvim.api.setHl(0, group, opts)
end

local function updateHiGroup(group, fg, bg, ex)
   local opts = { fg = fg, bg = bg }
   if ex then
      for k in ex:gmatch("[^,]+") do
         opts[k] = true
      end
   end
   setHl(group, opts)
end


local groups = {}
local actualHi = {}

setmetatable(color.scheme.hi, {
   __index = function(_self, key)
      return actualHi[key]
   end,
   __newindex = function(_self, key, val)
      if not val then
         setHl(key, { link = "NONE" })
         actualHi[key] = nil
      elseif groups[val] and key ~= groups[val] then

         setHl(key, { link = groups[val] })
         actualHi[key] = setmetatable({}, { __index = val })
      else

         actualHi[key] = val
         groups[val] = key
         updateHiGroup(key, val[1], val[2], val[3])
      end
   end,
})

color.scheme.groups = function()
   local idx
   local val
   return function()
      idx, val = next(actualHi, idx)
      if val then
         return idx, val[1], val[2], val[3]
      end
   end
end

function color.hexToRgb(hex)
   return bit32.rshift(hex, 16), bit32.band((bit32.rshift(hex, 8)), 0xff), bit32.band(hex, 0xff)
end

function color.rgbToHex(r, g, b)
   return bit32.bor(bit32.bor((bit32.lshift(r, 16)), (bit32.lshift(g, 8))), b)
end

function color.rgbToHsv(r, g, b)
   local rs = r / 255
   local gs = g / 255
   local bs = b / 255
   local mmax = math.max(rs, gs, bs)
   local mmin = math.min(rs, gs, bs)
   local delta = mmax - mmin

   local h
   if delta > 0 then
      if mmax == rs then
         h = (gs - bs) / delta
      elseif mmax == gs then
         h = (bs - rs) / delta + 2
      elseif mmax == bs then
         h = (rs - gs) / delta + 4
      end
   end

   local v = mmax
   local s = v == 0 and 0 or delta / v

   return h, s, v
end




function color.hsvToRgb(h, s, v)
   local alpha = v * (1 - s)
   local beta = h and v * (1 - (h - math.floor(h)) * s)
   local gamma = h and v * (1 - (1 - (h - math.floor(h))) * s)

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