
local a = vim.api
local util = {}

function util.partial<T, K>(f: function(...: T): K..., a: T): function(...: T): K...
	return function(...: T): K...
		return f(a, ...)
	end
end

function util.set<T>(t: {T}): {T:boolean}
	local s = {}
	for _, v in ipairs(t) do
		s[v] = true
	end
	return s
end

function util.xor(a: any, b: any): boolean
	return ((not a) and b as boolean) or (a as boolean and (not b))
end

function util.cmdf(fmt: string, ...: any)
	a.nvim_command(fmt:format(...))
end

function util.trim(s: string): string
	return (s:gsub("^%s*(.*)%s*$", "%1"))
end

global unpack: function<T>({T}): T...
-- TODO: fix
-- https://github.com/teal-language/tl/issues/237
function util.unpacker<T>(arr: {{T}}): (function(): T, T, T, T, T...)
	local i = 0
	return function(): T, T, T, T, T...
		i = i + 1
		return unpack(arr[i] or {})
	end
end

return util

