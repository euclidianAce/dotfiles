
local util = require("euclidian.lib.util")

local c = {scheme = {}, }






local Color = c.Color

c.scheme.hi = {}

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

setmetatable(c.scheme.hi, {
   __index = function(self, key)
      return actualHi[key]
   end,
   __newindex = function(self, key, val)
      if groups[val] then

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

function c.scheme.groups()
   return coroutine.wrap(function()
      for k, v in pairs(actualHi) do
         coroutine.yield(k, v[1], v[2], v[3])
      end
   end)
end

return c
