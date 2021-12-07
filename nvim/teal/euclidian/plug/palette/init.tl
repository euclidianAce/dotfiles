local api <const> = require("euclidian.plug.palette.api")
require("euclidian.lib.nvim").newCommand{
	name = "Theme",
	body = api.applyTheme,

	completelist = function(current: string): {string}
		local t <const> = {}
		local len <const> = #current
		for k in pairs(api.themes) do
			if current:lower() == k:lower():sub(1, len) then
				table.insert(t, k)
			end
		end
		table.sort(t)
		return t
	end,

	nargs = 1,
}

local record Options
	theme: string
end

return function(opts: Options)
	opts = opts or {}
	api.applyTheme(opts.theme or "default")
end
