local nvim = require("euclidian.lib.nvim")
local report = {}

function report.msg(str, ...)
   print("PackageManager:", string.format(str, ...))
end

function report.err(str, ...)
   nvim.api.errWrite("PackageManager: ")
   nvim.api.errWriteln(string.format(str, ...))
end

return report