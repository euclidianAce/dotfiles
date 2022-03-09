local nvim <const> = require("euclidian.lib.nvim")
local report <const> = {}

function report.msg(str: string, ...: any)
	print("PackageManager:", string.format(str, ...))
end

function report.err(str: string, ...: any)
	nvim.api.errWrite("PackageManager: ")
	nvim.api.errWriteln(string.format(str, ...))
end

return report
