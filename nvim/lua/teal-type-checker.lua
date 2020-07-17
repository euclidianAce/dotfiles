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
   return result.syntax_errors, result.type_errors
end

local function showErrors(buf, ns, errs)
   for i, err in ipairs(errs) do
      a.nvim_buf_set_virtual_text(buf, ns, err.y - 1, {
         { "✗ " .. err.msg, "Error" },
      }, {})
      a.nvim_buf_add_highlight(buf, ns, "Error", err.y - 1, err.x - 1, -1)
   end
end

function TypeChecker:annotateErrors()
   a.nvim_buf_clear_namespace(self.buffer, self.namespaceID, 0, -1)
   local synErrors, typeErrors = self:typeCheckBuffer()
   if #synErrors > 0 then
      showErrors(self.buffer, self.namespaceID, synErrors)
   else
      showErrors(self.buffer, self.namespaceID, typeErrors)
   end
end

return M
