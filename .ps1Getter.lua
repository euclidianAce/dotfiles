#!/bin/env lua

-- TODO:
-- 	- move some stuff to other files so they dont have to be reloaded everytime the script is run
-- 	- find a nice looking way of truncating things when terminal is too thin
--	- less verbose variable names for chunks

-- Functions to call bash functions and get varaibles
function bashExec(expr)
	local f = io.popen(expr)
	local out = f:read()
	f:close()
	return out
end

-- catches the output of a command by putting the echo into a temporary file and returns it
-- basically VAR=$( < `expr`)
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

-- but a string between non-printing characters so bash doesnt get confused when calculating length
local function esc(str)
	return table.concat{
		"\\[",		 -- surrounding brackets so bash knows not to count length
		string.char(27), -- escape, aka \e, \033, etc.
		"[",
		str, 		 -- escaped command
		"\\]"
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
		end,
		color = function(self, colorName)
			return chunk.esc[colorName] .. self .. chunk.esc.reset
		end
	}
}


chunk.box = {}
chunk.box.vline 	= newChunk("│",1)
chunk.box.hline 	= newChunk("─",1)
chunk.box.tlcorner 	= newChunk("┌",1)
chunk.box.blcorner 	= newChunk("└",1)
chunk.box.trcorner	= newChunk("┐",1)
chunk.box.brcorner	= newChunk("┘",1)
chunk.box.tleft 	= newChunk("┤",1)
chunk.box.tright 	= newChunk("├",1)
chunk.box.tdown		= newChunk("┬",1)
chunk.box.tup		= newChunk("┴",1)
chunk.box.cross		= newChunk("┼",1)

chunk.esc = {}
for i, v in pairs(ansiColors) do
	chunk.esc[i] = newChunk(esc(v),0)
end
chunk.esc.bold 	= newChunk(esc("1m"),0)
chunk.esc.reset = newChunk(esc("0m"),0)
chunk.newl 	= newChunk('\n',0)


-- User and terminal info

local columns 	= tonumber( bashEchoInto("$(stty size)"):gsub("(%d+)%s+(%d+)", "%2"), nil )

local user 	= newChunk(
			bashEchoInto("$USER") .. "@" .. bashExec("hostname")
		)

local workDir	= bashEchoInto("$DIRSTACK")
      workDir	= newChunk( workDir..(" "):rep(10-#workDir) ) -- Make the working directory at least 10 chars long 
      
local gitNoBranchStr = "* none"
local gitBranch = bashExec("git branch 2> /dev/null | grep \\*")
      gitBranch = (gitBranch and newChunk(gitBranch)) 
      		or newChunk(gitNoBranchStr)

local time 	= newChunk(os.date("%X"))

-- Helper functions
function concat(...)
	local rChunk = newChunk("")
	for _, v in ipairs{...} do
		rChunk = rChunk..v
	end
	return rChunk
end

local lineColor = "darkCyan"
local timeColor = "darkWhite"
local userColor = "red"
local workDirColor = "blue"
local gitColor = (gitBranch.str ~= gitNoBranchStr and "green") or "yellow"
-- PS1

if 10+time.len+user.len+workDir.len+gitBranch.len > columns then -- compact mode
	workDir = newChunk(bashEchoInto("$DIRSTACK")):color(workDirColor)
	local ps1 = concat(
		workDir, newChunk("$ "):color("magenta") 
	)

	io.write(ps1.str)
	return
end

-- first line
local firstLine = concat(
	chunk.esc[lineColor], 
	-- Initial Spaces
	newChunk((" "):rep(3)),
	-- Corner and T above time
	chunk.box.tlcorner, chunk.box.hline:rep(time.len), chunk.box.tdown,
	-- Ts above username
	chunk.box.hline:rep(user.len), chunk.box.tdown,
	-- Ts above working directory
	chunk.box.hline:rep(workDir.len), chunk.box.tdown,
	-- T and corner above git branch
	chunk.box.hline:rep(gitBranch.len), chunk.box.trcorner
)
local secondLine = concat(	
	chunk.box.tright, chunk.box.hline:rep(2), 
	chunk.box.tleft, 
	time:color(timeColor), 		chunk.box.vline:color(lineColor),
	user:color(userColor), 		chunk.box.vline:color(lineColor), 
	workDir:color(workDirColor), 	chunk.box.vline:color(lineColor), 
	gitBranch:color(gitColor), 	chunk.box.tright:color(lineColor)
)
local columnsLeft = columns - secondLine.len - 1
secondLine = concat(secondLine,
	chunk.esc[lineColor], chunk.box.hline:rep(columnsLeft), chunk.box.tleft
)
local thirdLine = concat(
	newChunk((" "):rep(3)), chunk.box.blcorner, chunk.box.hline:rep(time.len), chunk.box.tup, 
	chunk.box.hline:rep(user.len),

	chunk.box.tup, chunk.box.hline:rep(workDir.len),
	chunk.box.tup, chunk.box.hline:rep(gitBranch.len), chunk.box.brcorner
)

local fourthLine = newChunk("$ "):color("darkMagenta")



local ps1 = concat(firstLine, chunk.newl,  secondLine, chunk.newl, thirdLine, chunk.newl, fourthLine)
-- "return" the string to bash
io.write(ps1.str)
