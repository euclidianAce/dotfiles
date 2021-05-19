local report <const> = {}

function report.msg(str: string, ...: any)
	print("PackageManager:", string.format(str, ...))
end

function report.err(str: string, ...: any)
	vim.api.nvim_err_write("PackageManager: ")
	vim.api.nvim_err_writeln(string.format(str, ...))
end

return report
