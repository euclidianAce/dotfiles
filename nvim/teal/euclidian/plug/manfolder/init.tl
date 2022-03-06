local nvim <const> = require("euclidian.lib.nvim")

__euclidian.manfolder = function(): string | integer
	local lnum <const> = assert(vim.v.lnum) as integer
	-- Don't fold the title
	if lnum == 1 then
		return 0
	end
	local line <const> = nvim.Buffer():getLines(lnum-1, lnum, false)[1]

	-- if the line is empty, use the previous level
	if not line
		or #line == 0
		or line:match("^%s") as boolean
	then
		return "="
	elseif line:match("^[A-Z][A-Z%s]+$") as boolean then -- if the line is a title, it starts a fold
		return ">1"
	else -- otherwise, not folded
		return 0
	end
end

do
	local group <const> = "ManFolder"
	nvim.api.createAugroup(group, { clear = true })
	nvim.api.createAutocmd("FileType", {
		pattern = "man",
		command =  "setlocal foldexpr=v:lua.__euclidian.manfolder() | setlocal foldmethod=expr" ,
		group = group,
	})
end

return __euclidian.manfolder
