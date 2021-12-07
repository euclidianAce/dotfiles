local api = require("euclidian.plug.palette.api")
require("euclidian.lib.nvim").newCommand({
   name = "Theme",
   body = api.applyTheme,

   completelist = function(current)
      local t = {}
      local len = #current
      for k in pairs(api.themes) do
         if current:lower() == k:lower():sub(1, len) then
            table.insert(t, k)
         end
      end
      table.sort(t)
      return t
   end,

   nargs = 1,
})

local Options = {}



return function(opts)
   opts = opts or {}
   api.applyTheme(opts.theme or "default")
end