local sh <const> = require("euclidian.plug.spacehighlighter.api")

local record Options
	highlight: string
end

return function(opts: Options)
	opts = opts or {}
	sh.enable(opts.highlight)
end
