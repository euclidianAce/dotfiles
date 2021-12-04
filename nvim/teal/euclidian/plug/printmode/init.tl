local pm <const> = require("euclidian.plug.printmode.api")
local record Options
	mode: pm.Mode
end
return function(opts: Options)
	opts = opts or {}
	if opts.mode then pm.set(opts.mode) end
	pm.override()
end
