local nvim = require("euclidian.lib.nvim")
local api = require("euclidian.plug.palette.api")

local Options = {}



local function getCompletions(list, prefix)
   local t = {}
   local len = #prefix
   local lprefix = prefix:lower()
   for _, v in ipairs(list) do
      if lprefix == v:lower():sub(1, len) then
         table.insert(t, v)
      end
   end
   table.sort(t)
   return t
end

return function(opts)
   opts = opts or {}
   api.applyTheme(opts.theme or "default")

   nvim.newCommand({
      name = "Theme",
      body = api.applyTheme,

      completelist = function(current)
         local comp = getCompletions(vim.tbl_keys(api.themes), current)
         table.insert(comp, "random");
         return comp
      end,

      nargs = 1,
   })

   nvim.newCommand({
      name = "CustomTheme",
      body = api.applyHighlights,

      completelist = function(current)
         return getCompletions(vim.tbl_keys(api.dark), current)
      end,

      nargs = "+",
   })
end