local a = vim.api
local M = {}

local LuaBuffer = {}




local cache = setmetatable({}, { __mode = "v" })

local function getLuaBuf(buf)
   buf = buf or (vim.fn.bufnr())
   if cache[buf] then
      return cache[buf]
   end
   local ns = a.nvim_create_namespace("lua_stuffs")
   return {
      buf = buf,
      ns = ns,
   }
end




local function runBuffer(b)
   local printed = setmetatable({}, { __index = function(self, key)
         rawset(self, key, {})
         return rawget(self, key)
      end, })
   local code = table.concat(a.nvim_buf_get_lines(b.buf, 0, -1, false), "\n")
   local newPrint = function(...)
      local line = debug.getinfo(2, "l").currentline
      table.insert(
printed[line],
{ ... })

   end
   local ft = a.nvim_buf_get_option(b.buf, "ft")
   local chunk, err
   if ft == "teal" then
      chunk, err = loadstring((require("tl").gen(code)))
   else
      chunk, err = loadstring(code)
   end
   if err then
      print("Error:", err)
   end
   setfenv(chunk, setmetatable({}, {
      __index = function(_, key)
         if key == "print" then
            return newPrint
         end
         return _G[key]
      end,
   }))
   local ok, res = pcall(chunk)
   if not ok then
      print("Error:", res)
   end
   a.nvim_buf_clear_namespace(b.buf, b.ns, 0, -1)

   local offset = ft == "teal" and 0 or 1
   for linenum, data in pairs(printed) do
      local text = {}
      for _, arr in ipairs(data) do
         for _, v in ipairs(arr) do
            table.insert(text, { vim.inspect(v), "Comment" })
            table.insert(text, { " ", "Comment" })
         end
         table.insert(text, { "  ", "Comment" })
      end
      a.nvim_buf_set_virtual_text(b.buf, b.ns, linenum - offset, text, {})
   end
end

function M.runBuffer(buf)
   runBuffer(getLuaBuf(buf))
end

return M