
local a = vim.api
local util = {}

function util.xor(a: any, b: any): boolean
	return ((not a) and b as boolean) or (a as boolean and (not b))
end

function util.cmdf(fmt: string, ...: any)
	a.nvim_command(string.format(fmt, ...))
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

