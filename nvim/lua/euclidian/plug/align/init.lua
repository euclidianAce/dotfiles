local align = require("euclidian.plug.align.api")
local input = require("euclidian.lib.input")
local nvim = require("euclidian.lib.nvim")
local z = require("euclidian.lib.azync")

nvim.api.createUserCommand(
"Align",
z.asyncFn(function(args)
   if args.line1 == args.line2 then
      return
   end

   local buf = nvim.Buffer()


   local lines = buf:getLines(args.line1 - 1, args.line2, true)
   local pattern = #args.args ~= 0 and
   args.args or
   input.input({
      prompt = ("Align by %s: "):format(args.bang and "String" or "Pattern"),
   })

   if not pattern or #pattern == 0 then
      return
   end
   local aligned = align.byPattern(lines, pattern, not args.bang)
   vim.schedule(function()
      buf:setLines(args.line1 - 1, args.line2, true, aligned)
   end)
end),
{
   desc = "Align lines by a given pattern. (Use ! to align by a string instead)",
   range = true,
   bang = true,
   nargs = "?",
})