local locationjump <const> = require("euclidian.plug.locationjump.api")
local nvim <const> = require("euclidian.lib.nvim")

local record Options
	vmap: string
	openWith: locationjump.Opener
	pattern: string
end

return function(opts: Options)
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
			{ silent = true, desc = "jump to visually selected location" }
		)
	end

	if opts.pattern then
		locationjump.setPattern(opts.pattern)
	end
end
