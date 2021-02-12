
-- A cheap lua implementation of vim-commentary

local util <const> = require("euclidian.lib.util")
local a <const> = vim.api
local trim <const> = util.str.trim

local commenter <const> = {}

local escapeStr <const> = vim.pesc

local function split(str: string, delimiter: string): string, string
	local found = str:find(delimiter, 1, true)
	if not found then
		return str, ""
	end
	return str:sub(1, found - 1), str:sub(found + #delimiter, -1)
end

local function getCommentString(buf: number): string, string
	local ok, c = pcall(a.nvim_buf_get_option, buf, "commentstring") as (boolean, string)
	if not (ok and c) then
		print("[commenter] Couldn't get commentstring")
		return
	end
	local pre, post = split(c, "%s")
	return trim(pre), trim(post)
end

local function isCommented(csPre: string, csPost: string, str: string): boolean
	local commented = str:match("^%s*" .. escapeStr(csPre) .. " ?.-" .. escapeStr(csPost) .. "$")
	return commented as boolean
end

local function commentStr(pre: string, post: string, str: string): string
	if trim(str) == "" then return str end
	local ws, m = str:match("^(%s*)" .. escapeStr(pre) .. " ?(.-)%s*" .. escapeStr(post) .. "$")

	-- str is commented, uncomment it
	if ws then
		return ws .. m
	end

	pre = trim(pre)
	post = trim(post)

	-- str is uncommented, comment it
	local leadingWs, rest = str:match("^(%s*)(.*)$")
	return leadingWs .. pre .. " " .. rest .. (#post > 0 and " " .. post or "")
end

function commenter.commentLine(buf: number, lineNum: number)
	local pre, post = getCommentString(buf)

	if not pre then
		return
	end
	a.nvim_buf_set_lines(buf, lineNum-1, lineNum, false, {
		commentStr(pre, post, a.nvim_buf_get_lines(buf, lineNum-1, lineNum, false)[1])
	})
end

function commenter.commentRange(buf: number, start: number, finish: number)
	assert(buf, "no buffer")
	assert(start, "no start")
	assert(finish, "no finish")
	local lines <const> = a.nvim_buf_get_lines(buf, start, finish, false)
	if not lines[1] then
		return
	end
	local pre, post = getCommentString(buf)
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

