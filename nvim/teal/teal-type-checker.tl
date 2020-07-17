
local tl = require("tl")
local a = vim.api
local M = {}

local function getLines(buf: number): {string}
	return a.nvim_buf_get_lines(buf, 0, -1, false)
end


local TypeChecker = record
	buffer: number
	namespaceID: number
end
local register: {number:TypeChecker} = {}

local function typeChecker(buf: number): TypeChecker
	local tc = setmetatable({
		buffer = buf,
		namespaceID = a.nvim_create_namespace("Teal Type Errors")
	}, {__index = TypeChecker})
	register[buf] = tc
	return tc
end

function M.getTypeChecker(buf: number): TypeChecker
	if not buf or buf == 0 then
		buf = a.nvim_get_current_buf()
	end
	if not register[buf] then
		typeChecker(buf)
	end
	return register[buf]
end

local Error = record
   y: number
   x: number
   msg: string
   filename: string
end

function TypeChecker:typeCheckBuffer(): {Error}
	local lines = getLines(self.buffer)
	local result = tl.process_string(table.concat(lines, "\n"))
	return result.type_errors as {Error}
end

function TypeChecker:annotateTypeErrors()
	a.nvim_buf_clear_namespace(self.buffer, self.namespaceID, 0, -1)
	for i, err in ipairs(self:typeCheckBuffer()) do
		a.nvim_buf_set_virtual_text(self.buffer, self.namespaceID, err.y - 1, {
			{err.msg, "Error"}
		}, {})
	end
end

return M
