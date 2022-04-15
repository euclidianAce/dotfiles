local nvim <const> = require("euclidian.lib.nvim")
local color <const> = require("euclidian.lib.color")
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

	nvim.api.createUserCommand(
		"Theme",
		function(args: nvim.CommandArgs)
			api.applyTheme(args.args)
		end,
		{
			complete = function(current: string): {string}
				local comp <const> = getCompletions(vim.tbl_keys(api.themes), current)
				table.insert(comp, "random");
				return comp
			end,
			nargs = 1,
		}
	);

	nvim.api.createUserCommand(
		"CustomTheme",
		function(args: nvim.CommandArgs)
			api.applyHighlights(unpack(vim.split(args.args, " ") as {color.ColorName}))
		end,
		{
			nargs = "+",
			complete = function(current: string): {string}
				return getCompletions(vim.tbl_keys(api.dark), current)
			end,
		}
	)
end
