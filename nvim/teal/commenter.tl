
-- A cheap implementation of vim-commentary

local a = vim.api

local M = {}

local function escapeStr(str: string): string
	return (str:gsub("[-+.*()%[%]]", "%%%1"))
end

local function trim(str: string): string
	return str:match("%s*(.*)%s*")
end

function M.commentStr(cs: string, str: string): string
	if trim(str) == "" then
		return str
	end
	local escc = escapeStr(cs)
	local patt = escc:gsub("%%s", "(.*)")
	local leadingWhitespace, line: string, string = str:match("(%s*)(.*)")
	return leadingWhitespace .. (line:match(patt) or (cs:gsub("%%s", line)))
end

function M.commentLine(buf: number, lineNum: number)
	local c: string = a.nvim_buf_get_option(buf, "commentstring") as string
	if not c then
		print("Couldn't get commentstring")
		return
	end
	a.nvim_buf_set_lines(buf, lineNum-1, lineNum, false, {
		M.commentStr(c, a.nvim_buf_get_lines(buf, lineNum-1, lineNum, false)[1])
	})
end

return M
