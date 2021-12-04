local nvim <const> = require("euclidian.lib.nvim")
local locationjump <const> = require("euclidian.plug.locationjump.api")

local record Options
	vmap: string
	pattern: string
end

return function(opts: Options)
	opts = opts or {}
	if opts.vmap then
		nvim.setKeymap(
			"v",
			opts.vmap,
			"<esc>:lua require('euclidian.plug.locationjump').jumpToVisualSelection()<cr>",
			{ noremap = true, silent = true }
		)
	end
	if opts.pattern then locationjump.setPattern(opts.pattern) end
end
