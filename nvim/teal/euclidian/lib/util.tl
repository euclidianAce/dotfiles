
local a <const> = vim.api
local tab <const> = {}
local fn <const> = {}
local str <const> = {}
local nvim <const> = {}

function fn.partial<T, K>(f: function(...: T): K..., a: T): function(...: T): K...
	return function(...: T): K...
		return f(a, ...)
	end
end

function tab.set<T>(t: {T}): {T:boolean}
	local s = {}
	for _, v in ipairs(t) do
		s[v] = true
	end
	return s
end

local function xor(a: any, b: any): boolean
	return ((not a) and b as boolean) or (a as boolean and (not b))
end

function nvim.cmdf(fmt: string, ...: any)
	a.nvim_command(fmt:format(...))
end

local concat = table.concat
-- super simple autocmd wrapper
-- TODO: allow functions in expr
function nvim.autocmd(events: {string}, patts: {string}, expr: string)
	assert(#events > 0, "no events")
	assert(#patts > 0, "no patterns")
	assert(expr, "no expr")
	nvim.cmdf(
		"autocmd %s %s %s",
		concat(events, ","),
		concat(patts, ","),
		expr
	)
end

function str.trim(s: string): string
	return s:match("^%s*(.-)%s*$")
end

function tab.unpacker<T>(arr: {{T}}): function(): T...
	local i = 0
	return function(): T...
		i = i + 1
		return unpack(arr[i] or {})
	end
end

function tab.proxy<K, V>(t: {K:V}, index: function({K:V}, K), newindex: function({K:V}, K, V)): {K:V}
	return setmetatable({} as {K:V}, {
		__index = function(_: {K:V}, key: K): V
			if index then index(t, key) end
			return t[key]
		end,
		__newindex = function(_: {K:V}, key: K, val: V)
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

