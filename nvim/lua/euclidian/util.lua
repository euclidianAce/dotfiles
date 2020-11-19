
local a = vim.api
local util = {}

function util.xor(a, b)
   return ((not a) and b) or (a and (not b))
end

function util.cmdf(fmt, ...)
   a.nvim_command(string.format(fmt, ...))
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

return util
