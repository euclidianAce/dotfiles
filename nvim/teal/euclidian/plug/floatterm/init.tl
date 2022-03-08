local dialog <const> = require("euclidian.lib.dialog")
local terminal <const> = require("euclidian.lib.terminal")
local floatterm <const> = require("euclidian.plug.floatterm.api")

local terms <const> = {}

return function(
	opts: {{dialog.Dialog.Opts, string | {string}, terminal.Terminal.OpenOpts, floatterm.FloatTerm.Mappings}}
)
	for i, v in ipairs(opts) do
		terms[i] = floatterm.new(v[1], v[2], v[3], v[4])
	end
end
