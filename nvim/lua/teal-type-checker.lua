local tl = require("tl")
local a = vim.api
local M = {}

local function getLines(buf)
   return a.nvim_buf_get_lines(buf, 0, -1, false)
end


local TypeChecker = {}



local register = {}

local function typeChecker(buf)
   local tc = setmetatable({
      buffer = buf,
      namespaceID = a.nvim_create_namespace("Teal Type Errors"),
   }, { __index = TypeChecker })
   register[buf] = tc
   return tc
end

function M.getTypeChecker(buf)
   if not buf or buf == 0 then
      buf = a.nvim_get_current_buf()
   end
   if not register[buf] then
      typeChecker(buf)
   end
   return register[buf]
end

local Error = {}






function TypeChecker:typeCheckBuffer()
   local lines = getLines(self.buffer)
   local result = tl.process_string(table.concat(lines, "\n"))
   return result.type_errors
end

function TypeChecker:annotateTypeErrors()
   a.nvim_buf_clear_namespace(self.buffer, self.namespaceID, 0, -1)
   for i, err in ipairs(self:typeCheckBuffer()) do
      a.nvim_buf_set_virtual_text(self.buffer, self.namespaceID, err.y - 1, {
         { " <--- " .. err.msg, "Error" },
      }, {})
   end
end

return M
