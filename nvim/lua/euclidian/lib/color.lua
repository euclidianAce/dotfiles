
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

local function tiFmt(t, fmt, ...)
   table.insert(t, string.format(fmt, ...))
end


local function updateHiGroup(group, fg, bg, ex)
   local out = { "hi", group }
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

local groups = {}
local actualHi = {}

setmetatable(color.scheme.hi, {
   __index = function(_self, key)
      return actualHi[key]
   end,
   __newindex = function(_self, key, val)
      if not val then
         nvim.command("hi link %s NONE", key)
         actualHi[key] = nil
      elseif groups[val] and key ~= groups[val] then

         nvim.command("hi clear %s", key)
         nvim.command("hi link %s %s", key, groups[val])
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