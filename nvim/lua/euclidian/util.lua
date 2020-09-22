local M = {}

function M.wrapWith(f, a)
   local first = true
   local co = coroutine.create(f)
   return function(...)
      if first then
         first = false
         return select(2, assert(coroutine.resume(co, a)))
      else
         return select(2, assert(coroutine.resume(co, ...)))
      end
   end
end

function M.exhaust(f)
   local res = {}
   for val in f do
      table.insert(res, val)
   end
   return res
end

function M.zip(f1, f2)
   return function()
      return f1(), f2()
   end
end

function M.keys(arr)
   local key
   return function()
      key = next(arr, key)
      return key
   end
end

function M.values(arr)
   local key
   local val
   return function()
      key, val = next(arr, key)
      return val
   end
end

local fstr = "Attempt to %s protected table <%s>\n   with key \"%s\" %s%s"
function M.protected_proxy(t, err_handler)
   err_handler = err_handler or print
   local usage = {}
   for k, v in pairs(t) do
      table.insert(usage, tostring(k) .. ": " .. type(v))
   end
   local usage_str = "\nValid entries for <" .. tostring(t) .. "> {\n   " .. table.concat(usage, "\n   ") .. "\n}"
   return setmetatable({}, {
      __index = function(_, key)
         if t[key] == nil then
            err_handler(fstr:format("__index", tostring(t), tostring(key), "", usage_str))
            return
         end
         return t[key]
      end,
      __newindex = function(_, key, val)
         if t[key] == nil then
            err_handler(fstr:format("__index", tostring(t), tostring(key), "and " .. type(val) .. " value " .. tostring(val), usage_str))
            return
         end
         rawset(t, key, val)
      end,
   })
end

return M