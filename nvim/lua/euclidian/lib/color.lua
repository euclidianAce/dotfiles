
local bit = require("bit")
local util = require("euclidian.lib.util")

local color = {scheme = {}, }






color.scheme.hi = {}
local Color = color.Color

local function tiFmt(t, fmt, ...)
   table.insert(t, string.format(fmt, ...))
end
local function updateHiGroup(group, fg, bg, ex)
   local out = { "hi", group }
   if fg then       tiFmt(out, "guifg=#%06x", fg)
   else       tiFmt(out, "guifg=none") end
   if bg then       tiFmt(out, "guibg=#%06x", bg)
   else       tiFmt(out, "guibg=none") end
   if ex then       tiFmt(out, "gui=%s", ex)
   else       tiFmt(out, "gui=none") end
   util.cmdf(table.concat(out, " "))
end

local groups = {}
local actualHi = {}

setmetatable(color.scheme.hi, {
   __index = function(self, key)
      return actualHi[key]
   end,
   __newindex = function(self, key, val)
      if not val then
         util.cmdf("hi link %s NONE", key)
         actualHi[key] = nil
      elseif groups[val] then

         util.cmdf("hi clear %s", key)
         util.cmdf("hi link %s %s", key, groups[val])
         actualHi[key] = setmetatable({}, { __index = val })
      else

         actualHi[key] = val
         groups[val] = key
         updateHiGroup(key, val[1], val[2], val[3])
      end
   end,
})

function color.scheme.groups()
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
   return bit.rshift(hex, 16), bit.band(bit.rshift(hex, 8), 0x0000ff), bit.band(hex, 0x0000ff)
end

function color.rgbToHex(r, g, b)
   return bit.bor(
bit.lshift(r, 16),
bit.lshift(g, 8),
b)

end

return color
