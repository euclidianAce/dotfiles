local pm = require("euclidian.plug.printmode.api")
local Options = {}


return function(opts)
   opts = opts or {}
   if opts.mode then pm.set(opts.mode) end
   pm.override()
end