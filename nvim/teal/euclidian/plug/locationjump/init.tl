local locationjump <const> = require("euclidian.plug.locationjump.api")

local record Options
	vmap: string
	openCmd: string
	pattern: string
end

return function(opts: Options)
	opts = opts or {}
	if opts.vmap then
		vim.keymap.set(
			"v",
			opts.vmap,
			"<esc>:lua require('euclidian.plug.locationjump.api').jumpToVisualSelection("
				.. (opts.openCmd and ("%q"):format(opts.openCmd) or "") .. ")<cr>",
			{ silent = true, desc = "jump to visually selected location" }
		)
	end
	if opts.pattern then locationjump.setPattern(opts.pattern) end
end
