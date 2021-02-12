
local a = vim.api
local tab = {}
local fn = {}
local str = {}
local nvim = {}

function fn.partial(f, a)
   return function(...)
      return f(a, ...)
   end
end

function tab.set(t)
   local s = {}
   for _, v in ipairs(t) do
      s[v] = true
   end
   return s
end

local function xor(a, b)
   return ((not a) and b) or (a and (not b))
end

function nvim.cmdf(fmt, ...)
   a.nvim_command(fmt:format(...))
end

local concat = table.concat


function nvim.autocmd(events, patts, expr)
   assert(#events > 0, "no events")
   assert(#patts > 0, "no patterns")
   assert(expr, "no expr")
   nvim.cmdf(
   "autocmd %s %s %s",
   concat(events, ","),
   concat(patts, ","),
   expr)

end

function str.trim(s)
   return s:match("^%s*(.-)%s*$")
end

function tab.unpacker(arr)
   local i = 0
   return function()
      i = i + 1
      return unpack(arr[i] or {})
   end
end

function tab.proxy(t, index, newindex)
   return setmetatable({}, {
      __index = function(_, key)
         if index then index(t, key) end
         return t[key]
      end,
      __newindex = function(_, key, val)
         if newindex then newindex(t, key, val) end
         t[key] = val
      end,
   })
end

return {
   tab = tab,
   str = str,
   fn = fn,
   nvim = nvim,

   xor = xor,
}