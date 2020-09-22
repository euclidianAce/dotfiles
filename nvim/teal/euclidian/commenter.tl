
-- A cheap lua implementation of vim-commentary

local a = vim.api

local M = {}

local function escapeStr(str: string): string
	return (str:gsub("[-+.*()%[%]%%]", "%%%1"))
end

local function trim(str: string): string
	return str:match("%s*(.*)%s*")
end

local function split(str: string, delimiter: string): string, string
	local a, b = str:find(delimiter, 1, true)
	if not a then
		return str, ""
	end
	return str:sub(1, a - 1), str:sub(a + #delimiter, -1)
end

function M.commentStr(cs: string, str: string): string
	if trim(str) == "" then return str end

	local pre, post = split(cs, "%s")
	local ws, m = str:match("^(%s*)" .. escapeStr(pre) .. " ?(.-)" .. escapeStr(post) .. "$")

	-- uncommented string
	if ws then
		return ws .. m
	end

	-- commented string
	local leadingWs, rest = str:match("^(%s*)(.*)$")
	return leadingWs .. pre .. " " .. rest .. post
end

function M.commentLine(buf: number, lineNum: number)
	local ok, c = pcall(a.nvim_buf_get_option, buf, "commentstring")
	if not ok then
		print("[commenter] Couldn't get commentstring")
		return
	end
	a.nvim_buf_set_lines(buf, lineNum-1, lineNum, false, {
		M.commentStr(c as string, a.nvim_buf_get_lines(buf, lineNum-1, lineNum, false)[1])
	})
end

return M
