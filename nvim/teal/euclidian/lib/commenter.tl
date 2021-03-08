
-- A cheap lua implementation of vim-commentary

local nvim <const> = require("euclidian.lib.nvim")

local trim <const> = vim.trim

local commenter <const> = {}

local escapeStr <const> = vim.pesc

local function split(str: string, delimiter: string): string, string
	local found = str:find(delimiter, 1, true)
	if not found then
		return str, ""
	end
	return str:sub(1, found - 1), str:sub(found + #delimiter, -1)
end

local function getCommentString(buf: integer): string, string
	local c = nvim.Buffer(buf):getOption("commentstring")
	if not c then
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

function commenter.commentLine(buf: integer, lineNum: integer)
	local pre, post = getCommentString(buf)

	if not pre then
		return
	end

	local b <const> = nvim.Buffer(buf)
	b:setLines(lineNum-1, lineNum, false, {
		commentStr(pre, post, b:getLines(lineNum-1, lineNum, false)[1])
	})
end

local function xor(a: any, b: any): boolean
	return (not a and b as boolean) or (a as boolean and not b)
end

function commenter.commentRange(buf: integer, start: integer, finish: integer)
	assert(buf, "no buffer")
	assert(start, "no start")
	assert(finish, "no finish")
	local b <const> = nvim.Buffer(buf)
	local lines <const> = b:getLines(start, finish, false)
	if not lines[1] then
		return
	end
	local pre, post = getCommentString(buf)
	local shouldBeCommented <const> = not isCommented(pre, post, lines[1])

	lines[1] = commentStr(pre, post, lines[1])
	for i = 2, #lines do
		if xor(shouldBeCommented, isCommented(pre, post, lines[i])) then
			lines[i] = commentStr(pre, post, lines[i])
		end
	end
	b:setLines(start, finish, false, lines)
end

return commenter

