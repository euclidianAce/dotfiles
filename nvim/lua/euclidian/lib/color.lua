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

return color