local sh = require("euclidian.plug.spacehighlighter.api")

local Options = {}



return function(opts)
   opts = opts or {}
   sh.enable(opts.highlight)
end