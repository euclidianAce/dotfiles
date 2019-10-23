#!/bin/env lua

function bashEval(expr)
	local f = io.popen("echo "..expr)
	local out = f:read()
	f:close()
	return out
end

local columns 	= tonumber( bashEval("$(stty size)"):gsub("(%d+)%s+(%d+)", "%2"), nil ) 
local user 	= bashEval("$USER")
local workDir	= bashEval("$DIRSTACK")

--allcaps if root
user = (user=="root" and user:upper()) or user

local ansiColors = {
	white 		= "1;37m",
	gray 		= "37m",
	lightBlue 	= "1;34m",
	blue 		= "34m",
	green 		= "1;36m",
	red 		= "31m",
	purple 		= "35m",
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

local function norm()
	return esc("0m")
end

-- new string
-- 	normal chars have length 1 and nothing special
-- 	box drawing chars have actual length 3
-- 	escaped sequences have length 0

local chunk = {}
local chunkMt 

local function newChunk(str, len)
	if not len then len = #str end
	return setmetatable({str=str, len=len}, chunkMt)
end

chunkMt = {
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
chunk.box.vline = newChunk("│",1)
chunk.box.hline = newChunk("─",1)
chunk.box.tlcorner = newChunk("┌",1)
chunk.box.blcorner = newChunk("└",1)
chunk.box.tleft = newChunk("┤",1)
chunk.box.tright = newChunk("├",1)

chunk.esc = {}
for i, v in pairs(ansiColors) do
	chunk.esc[i] = newChunk(esc(v),0)
end
chunk.esc.reset = newChunk(norm(),0)

chunk.newl = newChunk('\n',0)

user = newChunk(user)
workDir = newChunk(workDir)

local str = newChunk("",0)
local function append(...)
	for i, v in ipairs{...} do
		str = str..v
	end
end

append(
	chunk.esc.gray, chunk.box.tlcorner, chunk.box.hline:rep(8), 
	chunk.box.tleft, chunk.esc.red,   	user,	 				chunk.esc.gray, chunk.box.tright, 
	chunk.box.tleft, chunk.esc.lightBlue,  	workDir, 				chunk.esc.reset, chunk.esc.gray, chunk.box.tright,
	chunk.box.tleft, chunk.esc.green, 	newChunk("Insert Git Branch Here"), 	chunk.esc.reset, chunk.esc.gray, chunk.box.tright
)
local columnsLeft = columns - str.len - 1
append(
	chunk.box.hline:rep(columnsLeft), chunk.box.tleft, chunk.esc.reset, chunk.newl,
	chunk.esc.gray, chunk.box.blcorner, chunk.box.hline:rep(2), chunk.box.tleft,
	chunk.esc.purple, newChunk("$ "), chunk.esc.reset
)



local ps1 = str.str
-- "return" the string to bash
io.write(ps1)
