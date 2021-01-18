
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

function util.trim(s)
   return (s:gsub("^%s*(.*)%s*$", "%1"))
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
         if index then             index(t, key) end
         return t[key]
      end,
      __newindex = function(_, key, val)
         if newindex then             newindex(t, key, val) end
         t[key] = val
      end,
   })
end

return util
