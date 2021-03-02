local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; local a = vim.api
local function unCamel(s)
   return (s:gsub("[A-Z]", function(m)
      return "_" .. m:lower()
   end))
end
local function genMetatable(t, prefix)
   local cache = {}
   return {
      __call = function(_, n)
         if not n or n == 0 then
            n = a["nvim_get_current_" .. prefix]()
         end
         if not cache[n] then
            cache[n] = setmetatable({ id = n }, { __index = t })
         end
         return cache[n]
      end,
      __index = function(_, key)
         local fn = a["nvim_" .. prefix .. "_" .. unCamel(key)]
         return fn and function(self, ...)
            return fn(self.id, ...)
         end
      end,
   }
end

local MapOpts = {}








local Buffer = {}































































































































setmetatable(Buffer, genMetatable(Buffer, "buf"))

local Window = {Config = {}, }







































































































setmetatable(Window, genMetatable(Window, "win"))

local Tab = {}













setmetatable(Tab, genMetatable(Tab, "tabpage"))


return {
   Buffer = Buffer,
   Window = Window,
   Tab = Tab,
   MapOpts = MapOpts,
}