
-- A cheap lua implementation of vim-commentary

local util = require("euclidian.lib.util")
local a = vim.api

local commenter = {}

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

local function getCommentString(buf: number): string
	local ok, c = pcall(a.nvim_buf_get_option, buf, "commentstring") as (boolean, string)
	if not ok then
		print("[commenter] Couldn't get commentstring")
		return
	end
	return c
end

local function isCommented(csPre: string, csPost: string, str: string): boolean
	local commented = str:match("^%s*" .. escapeStr(csPre) .. " ?.-" .. escapeStr(csPost) .. "$")
	return commented as boolean
end

local function commentStr(pre: string, post: string, str: string): string
	if trim(str) == "" then return str end
	local ws, m = str:match("^(%s*)" .. escapeStr(pre) .. " ?(.-)" .. escapeStr(post) .. "$")

	-- str is commented, uncomment it
	if ws then
		return ws .. m
	end

	-- str is uncommented, comment it
	local leadingWs, rest = str:match("^(%s*)(.*)$")
	return leadingWs .. pre .. " " .. rest .. post
end

function commenter.commentLine(buf: number, lineNum: number)
	local cs = getCommentString(buf)
	if not cs then
		return
	end
	local pre, post = split(cs, "%s")
	a.nvim_buf_set_lines(buf, lineNum-1, lineNum, false, {
		commentStr(pre, post, a.nvim_buf_get_lines(buf, lineNum-1, lineNum, false)[1])
	})
end

function commenter.commentRange(buf: number, start: number, finish: number)
	local lines <const> = a.nvim_buf_get_lines(buf, start, finish, false)
	local cs <const> = getCommentString(buf)
	local pre, post = split(cs, "%s")
	local shouldBeCommented <const> = not isCommented(pre, post, lines[1])

	lines[1] = commentStr(pre, post, lines[1])
	for i = 2, #lines do
		if util.xor(shouldBeCommented, isCommented(pre, post, lines[i])) then
			lines[i] = commentStr(pre, post, lines[i])
		end
	end
	a.nvim_buf_set_lines(buf, start, finish, false, lines)
end

return commenter
