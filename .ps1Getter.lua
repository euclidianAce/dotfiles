#!/bin/env lua

-- Functions to call bash functions and get varaibles
function bashExec(expr)
	local f = io.popen(expr)
	local out = f:read()
	f:close()
	return out
end

-- catches the output of a command by putting the echo into a temporary file and returns it
function bashEchoInto(expr)
	return bashExec("echo "..expr)
end


local ansiColors = {
	black	= "90m",
	red	= "91m",
	green	= "92m",
	yellow	= "93m",
	blue	= "94m",
	magenta	= "95m",
	cyan	= "96m",
	white	= "97m",

	darkBlack	= "30m",
	darkRed		= "31m",
	darkGreen	= "32m",
	darkYellow	= "33m",
	darkBlue	= "34m",
	darkMagenta	= "35m",
	darkCyan	= "36m",
	darkWhite	= "37m"
}


local function esc(str)
	return table.concat{
		string.char(31),  	-- non printing ascii char
		string.char(27),	-- escape
		"[",
		str, 		 	-- escaped command
		string.char(31)   	-- non printing ascii char
	}
end

-- chunk object
-- 	basically a string except when you want the length to be different
-- 	since the box drawing characters count as length 3 we want to accurately calculate the length of the string
-- 	also escaped characters for colors and bold should count as length 0
--
-- 	this is an object that lets you define the length of the string you give it
local chunk = {}
local chunkMt 

local function newChunk(str, len)
	if not len then len = #str end
	return setmetatable({str=str, len=len}, chunkMt)
end

chunkMt = {
	__metatable = "chunk",
	__concat = function(a, b)
		return newChunk( a.str..b.str, a.len+b.len )
	end,
	__index = {
		rep = function(self, num)
			return newChunk( self.str:rep(num), self.len*num )
		end
	}
}


chunk.box = {}
chunk.box.vline 	= newChunk("│",1)
chunk.box.hline 	= newChunk("─",1)
chunk.box.tlcorner 	= newChunk("┌",1)
chunk.box.blcorner 	= newChunk("└",1)
chunk.box.tleft 	= newChunk("┤",1)
chunk.box.tright 	= newChunk("├",1)

chunk.esc = {}
for i, v in pairs(ansiColors) do
	chunk.esc[i] = newChunk(esc(v),0)
end
chunk.esc.bold 	= newChunk(esc("1m"),0)
chunk.esc.reset = newChunk(esc("0m"),0)
chunk.newl 	= newChunk('\n',0)


-- User and terminal info

local columns 	= tonumber( 
			bashEchoInto("$(stty size)"):gsub("(%d+)%s+(%d+)", "%2"), nil 
		) 
local user 	= newChunk(
			bashEchoInto("$USER") .. "@" .. bashEchoInto("$HOSTNAME")
		)
local workDir	= newChunk(
			bashEchoInto("$DIRSTACK")
		)
local gitBranch = bashExec("git branch 2> /dev/null | grep \\*")
      gitBranch = (gitBranch and newChunk(gitBranch)) 
      		or newChunk("* no repo here")

local time 	= newChunk(os.date("%X"))


-- PS1
local str = newChunk("",0)
function append(...)
	for _, v in ipairs{...} do
		if type(v) == "table" and getmetatable(v) ~= "chunk" then
			for __, w in ipairs(v) do
				str = str..w
			end
		else
			str = str..v
		end
	end
end
local unpack = table.unpack or unpack
local function container(color, ...)
	local args = {...}
	table.insert(args, 1, chunk.box.tleft)
	table.insert(args, 2, chunk.esc[color])
	table.insert(args, chunk.esc.reset)
	table.insert(args, chunk.esc.darkCyan)
	table.insert(args, chunk.box.tright)
	return unpack{args}
end

append(
	chunk.esc.darkCyan, chunk.box.tlcorner, chunk.box.hline:rep(4), 
	container("darkWhite", 	time), 
	container("red", 	user),
	container("blue", 	
	      chunk.esc.bold, 	workDir),
	container(
	(gitBranch.str=="* no repo here" and "green") or "darkGreen",
				gitBranch)
)
local columnsLeft = columns - str.len - 1
append(
	chunk.box.hline:rep(columnsLeft), chunk.box.tleft, chunk.esc.reset, chunk.newl,
	chunk.esc.darkCyan, chunk.box.blcorner, chunk.box.hline:rep(2), chunk.box.tleft,
	chunk.esc.darkMagenta, newChunk("$ "), chunk.esc.reset
)



local ps1 = str.str
-- "return" the string to bash
io.write(ps1)
