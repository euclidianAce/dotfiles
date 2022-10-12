local nvim = require("euclidian.lib.nvim")
local color = require("euclidian.lib.color")
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

   nvim.api.createUserCommand(
   "Theme",
   function(args)
      api.applyTheme(args.args, args.bang)
   end,
   {
      complete = function(current)
         local comp = getCompletions(vim.tbl_keys(api.themes), current)
         table.insert(comp, "random");
         return comp
      end,
      bang = true,
      nargs = 1,
   });


   nvim.api.createUserCommand(
   "CustomTheme",
   function(args)
      api.applyHighlights(args.bang, unpack(vim.split(args.args, " ")))
   end,
   {
      bang = true,
      nargs = "+",
      complete = function(current)
         return getCompletions(vim.tbl_keys(api.dark), current)
      end,
   })

end