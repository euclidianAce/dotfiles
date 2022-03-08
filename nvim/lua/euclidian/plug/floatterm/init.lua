local dialog = require("euclidian.lib.dialog")
local terminal = require("euclidian.lib.terminal")
local floatterm = require("euclidian.plug.floatterm.api")

local terms = {}

return function(
   opts)

   for i, v in ipairs(opts) do
      terms[i] = floatterm.new(v[1], v[2], v[3], v[4])
   end
end