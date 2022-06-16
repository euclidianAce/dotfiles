local align <const> = require("euclidian.plug.align.api")
local input <const> = require("euclidian.lib.input")
local nvim <const> = require("euclidian.lib.nvim")
local z <const> = require("euclidian.lib.azync")

nvim.api.createUserCommand(
	"Align",
	z.asyncFn(function(args: nvim.CommandArgs)
		if args.line1 == args.line2 then
			return
		end

		local buf <const> = nvim.Buffer()
		-- lines given by command args are 1-based and closed-range
		-- api is 0 based and half-open-range
		local lines <const> = buf:getLines(args.line1 - 1, args.line2, true)
		local pattern <const> = #args.args ~= 0
			and args.args
			or input.input{
				prompt = ("Align by %s: "):format(args.bang and "String" or "Pattern")
			}

		if not pattern or #pattern == 0 then
			return
		end
		local aligned <const> = align.byPattern(lines, pattern, not args.bang)
		vim.schedule(function()
			buf:setLines(args.line1 - 1, args.line2, true, aligned)
		end)
	end),
	{
		desc = "Align lines by a given pattern. (Use ! to align by a string instead)",
		range = true,
		bang = true,
		nargs = "?",
	}
)
