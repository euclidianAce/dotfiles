local locationjump = require("euclidian.plug.locationjump.api")
local nvim = require("euclidian.lib.nvim")

local Options = {}





return function(opts)
   opts = opts or {}
   if opts.vmap then
      vim.keymap.set(
      "v",
      opts.vmap,
      function()
         nvim.api.feedkeys("", 'v', true)
         vim.schedule(function()
            locationjump.jumpToVisualSelection(opts.openWith)
         end)
      end,
      { silent = true, desc = "jump to visually selected location" })

   end

   if opts.pattern then
      locationjump.setPattern(opts.pattern)
   end
end