local nvim = require("euclidian.lib.nvim")
local locationjump = require("euclidian.plug.locationjump.api")

local Options = {}




return function(opts)
   opts = opts or {}
   if opts.vmap then
      nvim.setKeymap(
      "v",
      opts.vmap,
      "<esc>:lua require('euclidian.plug.locationjump.api').jumpToVisualSelection()<cr>",
      { noremap = true, silent = true })

   end
   if opts.pattern then locationjump.setPattern(opts.pattern) end
end