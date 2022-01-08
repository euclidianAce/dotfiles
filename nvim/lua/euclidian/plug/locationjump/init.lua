local locationjump = require("euclidian.plug.locationjump.api")

local Options = {}




return function(opts)
   opts = opts or {}
   if opts.vmap then
      vim.keymap.set(
      "v",
      opts.vmap,
      "<esc>:lua require('euclidian.plug.locationjump.api').jumpToVisualSelection()<cr>",
      { silent = true })

   end
   if opts.pattern then locationjump.setPattern(opts.pattern) end
end