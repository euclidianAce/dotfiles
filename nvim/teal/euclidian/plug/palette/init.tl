local nvim <const> = require("euclidian.lib.nvim")
local api <const> = require("euclidian.plug.palette.api")

local record Options
	theme: string
end

local function getCompletions(list: {string}, prefix: string): {string}
	local t <const> = {}
	local len <const> = #prefix
	local lprefix <const> = prefix:lower()
	for _, v in ipairs(list) do
		if lprefix == v:lower():sub(1, len) then
			table.insert(t, v)
		end
	end
	table.sort(t)
	return t
end

return function(opts: Options)
	opts = opts or {}
	api.applyTheme(opts.theme or "default")

	nvim.newCommand{
		name = "Theme",
		body = api.applyTheme,

		completelist = function(current: string): {string}
			return getCompletions(vim.tbl_keys(api.themes), current)
		end,

		nargs = 1,
	}

	nvim.newCommand{
		name = "CustomTheme",
		body = api.applyHighlights,

		completelist = function(current: string): {string}
			return getCompletions(vim.tbl_keys(api.dark), current)
		end,

		nargs = "+",
	}
end
