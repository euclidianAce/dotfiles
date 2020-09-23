
local a = vim.api
local M = {}

local record LuaBuffer
	buf: number
	ns: number
end

local cache: {number:LuaBuffer} = setmetatable({}, {__mode = "v"})

local function getLuaBuf(buf: number): LuaBuffer
	buf = buf or (vim.fn.bufnr() as number)
	if cache[buf] then
		return cache[buf]
	end
	local ns = a.nvim_create_namespace("lua_stuffs")
	return {
		buf = buf,
		ns = ns,
	}
end

global setfenv: function(function, table): function
global loadstring: function(string, table): function, string

local function runBuffer(b: LuaBuffer)
	local printed: {number:{{any}}} = setmetatable({}, {__index = function(self: table, key: number): {any}
		rawset(self, key, {})
		return rawget(self, key) as {any}
	end})
	local code = table.concat(a.nvim_buf_get_lines(b.buf, 0, -1, false), "\n")
	local newPrint = function(...)
		local line = debug.getinfo(2, "l").currentline
		table.insert(
			printed[line],
			{...}
		)
	end
	local ft = a.nvim_buf_get_option(b.buf, "ft")
	local chunk, err: function, string
	if ft == "teal" then
		chunk, err = loadstring((require("tl").gen(code)))
	else
		chunk, err = loadstring(code)
	end
	if err then
		print("Error:", err)
	end
	setfenv(chunk, setmetatable({}, {
		__index = function(_: table, key: string): any
			if key == "print" then
				return newPrint
			end
			return _G as {string:any}[key]
		end
	}))
	local ok, res = pcall(chunk)
	if not ok then
		print("Error:", res)
	end
	a.nvim_buf_clear_namespace(b.buf, b.ns, 0, -1)
	-- TODO: do something upstream about this
	local offset = ft == "teal" and 0 or 1
	for linenum, data in pairs(printed) do
		local text: {{string}} = {}
		for _, arr in ipairs(data) do
			for _, v in ipairs(arr) do
				table.insert(text, {vim.inspect(v) as string, "Comment"})
				table.insert(text, {" ", "Comment"})
			end
			table.insert(text, {"  ", "Comment"})
		end
		a.nvim_buf_set_virtual_text(b.buf, b.ns, linenum - offset, text, {})
	end
end

function M.runBuffer(buf: number)
	runBuffer(getLuaBuf(buf))
end

return M
