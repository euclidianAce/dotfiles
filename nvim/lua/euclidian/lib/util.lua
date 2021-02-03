
local a = vim.api
local util = {}

function util.partial(f, a)
   return function(...)
      return f(a, ...)
   end
end

function util.set(t)
   local s = {}
   for _, v in ipairs(t) do
      s[v] = true
   end
   return s
end

function util.xor(a, b)
   return ((not a) and b) or (a and (not b))
end

function util.cmdf(fmt, ...)
   a.nvim_command(fmt:format(...))
end

local concat = table.concat


function util.autocmd(events, patts, expr)
   assert(#events > 0, "no events")
   assert(#patts > 0, "no patterns")
   assert(expr, "no expr")
   util.cmdf(
   "autocmd %s %s %s",
   concat(events, ","),
   concat(patts, ","),
   expr)

end

function util.trim(str)
   return str:match("^%s*(.-)%s*$")
end

function util.unpacker(arr)
   local i = 0
   return function()
      i = i + 1
      return unpack(arr[i] or {})
   end
end

function util.proxy(t, index, newindex)
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

return util
