local report = {}

function report.msg(str, ...)
   print("PackageManager:", string.format(str, ...))
end

function report.err(str, ...)
   vim.api.nvim_err_write("PackageManager: ")
   vim.api.nvim_err_writeln(string.format(str, ...))
end

return report