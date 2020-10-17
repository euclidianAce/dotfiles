
local M = {}

function M.wrapWith(f: function, a: any): function
	local first = true
	local co = coroutine.create(f)
	return function(...: any): any...
		if first then
			first = false
			return select(2, assert(coroutine.resume(co, a)))
		else
			return select(2, assert(coroutine.resume(co, ...)))
		end
	end
end

function M.exhaust<T>(f: function(): T): {T}
	local res: {T} = {}
	for val in f do
		table.insert(res, val)
	end
	return res
end

function M.zip <T, K>(f1: (function(): T), f2: (function(): K)): function(): T, K
	return function(): T, K
		return f1(), f2()
	end
end

function M.keys<T>(arr: {T:any}): function(): T
	local key: T
	return function(): T
		key = next(arr, key)
		return key
	end
end

function M.values<K, V>(arr: {K:V}): function(): V
	local key: K
	local val: V
	return function(): V
		key, val = next(arr, key)
		return val
	end
end

local fstr <const> = "Attempt to %s protected table <%s>\n   with key \"%s\" %s%s"
function M.protected_proxy(t: {string:any}, err_handler: function(string)): {string:any}
   err_handler = err_handler or print as function(string)
   local usage: {string} = {}
   for k, v in pairs(t) do
      table.insert(usage, tostring(k) .. ": " .. type(v))
   end
   local usage_str = "\nValid entries for <" .. tostring(t) .. "> {\n   " .. table.concat(usage, "\n   ") .. "\n}"
   return setmetatable({}, {
      __index = function(_: table, key: any): any
         if t[key as string] == nil then
            err_handler(fstr:format("__index", tostring(t), tostring(key), "", usage_str))
            return
         end
         return t[key as string]
      end,
      __newindex = function(_: table, key: any, val: any)
         if t[key as string] == nil then
            err_handler(fstr:format("__index", tostring(t), tostring(key), "and " .. type(val) .. " value " .. tostring(val), usage_str))
            return
         end
         rawset(t, key as string, val)
      end,
   })
end

return M
