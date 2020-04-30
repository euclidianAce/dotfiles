
local os = require("os")
local table = require("table")
local tinsert, tconcat = table.insert, table.concat
local utf8
do
	local ok, msg = pcall(require, "utf8")
	if ok then
		utf8 = msg
	else
		utf8 = {
			len = function(str)
				return #str
			end
		}
	end
end

-- {{{ Box Drawing Chars
local c = utf8.char
local line = {
	horiz = "─", --c(0x2500),
	vert = "│", --c(0x2502),
	--cross = "", --c(0x253c),
}
local corner = {
	tl = "┌", --c(0x250c),
	tr = "┐", --c(0x2510),
	bl = "└", --c(0x2514),
	br = "┘", --c(0x2518),
}
local t = {
	up = "┴", --c(0x2534),
	down = "┬", --c(0x252c),
	left = "┤", --c(0x2524),
	right = "├", --c(0x251c),
}
-- }}}
-- {{{ Environment vars
local function sh(expr)
	local f = io.popen(expr)
	local out = f:read()
	f:close()
	return out
end
local columns = tonumber(sh("stty size"):match("%d+ (%d+)"))
local time = os.date("%X")
local user = os.getenv("USER")
local host = sh("hostname")
local wd = sh("pwd"):gsub("^/home/" .. user, "~")
local branch = sh("git branch 2> /dev/null | grep \\*")
-- }}}
-- {{{ Directory shortener
do
	local dirmaxlen = 12
	local dirminlen = 7
	local dirstack = {}
	for dir in wd:gmatch("[^/]+") do
		tinsert(dirstack, #dir > dirmaxlen and dir:sub(1, dirmaxlen-3).."..." or dir)
	end
	local home = dirstack[1] == "~"
	if #dirstack > 3 then
		local idx = home and 2 or 1
		repeat 
			table.remove(dirstack, idx)
		until #dirstack <= 3
		table.insert(dirstack, idx, "...")
	end
	wd = (home and "" or "/") .. tconcat(dirstack, "/")
	wd = wd .. (" "):rep(dirminlen-#wd)
end
-- }}}
-- {{{ The Main Bits
local entries = {}
local escChar = "\\[" .. string.char(27) .. "["
local reset = escChar .. "0m\\]"
local function createEntry(str, color)
	if str then
		tinsert(entries, {
			str = str,
			color = escChar .. color .. "m\\]",
		})
	end
end

createEntry(time, "37")
createEntry(user .. "@" .. host, "31")
createEntry(wd, "1;34")
createEntry(branch, "32")

local result = {{},{},{}}
local middleLen = #entries
for idx, entry in ipairs(entries) do
	tinsert(result[1], line.horiz:rep(utf8.len(entry.str)))
	middleLen = middleLen + utf8.len(entry.str)
	tinsert(result[2], entry.color .. entry.str .. reset)
	tinsert(result[3], line.horiz:rep(utf8.len(entry.str)))
end
middleLen = middleLen + 5
local lineColor = escChar .. "36m\\]"
if middleLen > columns then
	io.write(lineColor, corner.tl, t.left, reset, entries[3].color, entries[3].str, reset, lineColor, t.right)
	io.write(line.horiz:rep(columns - (4+#entries[3].str)), t.left)
	io.write("\n", lineColor, corner.bl, line.horiz, t.left, entries[2].color, entries[2].str, escChar, "35m\\] $ ", reset)
	return
end
-- fisrt line
io.write("   ", lineColor, corner.tl, tconcat(result[1], t.down), corner.tr, "\n")
-- second line
io.write(corner.tl, line.horiz:rep(2), t.left, tconcat(result[2], reset .. lineColor .. line.vert), lineColor, t.right)
io.write(line.horiz:rep(columns - middleLen), t.left, "\n")
-- third line
io.write(lineColor, line.vert, "  ", corner.bl, tconcat(result[3], t.up), corner.br, "\n")
io.write(lineColor, corner.bl, t.left, escChar .. "35m\\]$ ", reset)
-- }}}
