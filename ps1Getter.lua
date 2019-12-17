#!/bin/env lua

-- TODO:
-- 	- find a nice looking way of truncating things when terminal is too thin

-- make chunk library gets loaded from the relative file location
package.path = package.path .. ";/home/corey/.config/?.lua"
local chunk = require "chunk"


local box = chunk.box
local color = chunk.color
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

-- User and terminal info

local columns 	= tonumber( bashEchoInto("$(stty size)"):gsub("(%d+)%s+(%d+)", "%2"), nil )

local user 	= chunk.new(
			bashEchoInto("$USER") .. "@" .. bashExec("hostname")
		)

local workDir	= bashEchoInto("$DIRSTACK") or ""
if workDir == "" then
	workDir = bashExec("pwd"):gsub("/home/"..bashEchoInto("$USER"), "~")
end
workDir	= chunk.new( workDir..(" "):rep(10-#workDir) ) -- Make the working directory at least 10 chars long 
      
local gitNoBranchStr = "* none"
local gitBranch = bashExec("git branch 2> /dev/null | grep \\*")
      gitBranch = (gitBranch and chunk.new(gitBranch)) 
      		or chunk.new(gitNoBranchStr)

local time 	= chunk.new(os.date("%X"))
-- corresponding colors
local lineColor = "cyan"
local timeColor = "white"
local userColor = "lightRed"
local workDirColor = "lightBlue"
local gitColor = (gitBranch.str ~= gitNoBranchStr and "lightGreen") or "lightYellow"

-- PS1

if 10+time.len+user.len+workDir.len+gitBranch.len > columns then -- compact mode
	
	workDir = chunk.new(bashEchoInto("$DIRSTACK")):color(workDirColor)
	local ps1 = chunk.concat{
		workDir, chunk.newl, chunk.new("$ "):color("lightMagenta")
	}

	io.write(ps1.str)
	return
end

local ps1 = {
	chunk.concat{
	-- line 1, the hats to the info

	--[[ Set the lineColor ]] 	color[lineColor],
	--[[ Initial Spaces ]] 		chunk.new(" "):rep(3),
	--[[ Corner and T above time]] 	box.corner.topLeft, box.line.horizontal:rep(time.len), box.t.down,
	--[[ Ts above user@host ]] 	box.line.horizontal:rep(user.len), box.t.down,
	--[[ Ts above directory ]] 	box.line.horizontal:rep(workDir.len), box.t.down,
	--[[ corner above git branch ]] box.line.horizontal:rep(gitBranch.len), box.corner.topRight,
					chunk.newl,
	},

	chunk.concat{
		-- line 2, the info and the separators for it
		
		-- initial stuffs
		box.corner.topLeft, box.line.horizontal:rep(2), box.t.left, chunk.reset,
		--   INFO				SEPARATOR
		time:color(timeColor), 		box.line.vertical:color(lineColor),
		user:color(userColor),		box.line.vertical:color(lineColor),
		workDir:color(workDirColor),	box.line.vertical:color(lineColor),
		gitBranch:color(gitColor),	color[lineColor], box.t.right,
	},

	-- line 3, the bottom bits
	chunk.concat{
	--[[ Set the lineColor ]] 	color[lineColor], box.line.vertical,
	--[[ Initial Spaces ]] 		chunk.new(" "):rep(2),
	--[[ Corner and T above time]] 	box.corner.bottomLeft, box.line.horizontal:rep(time.len), box.t.up,
	--[[ Ts above user@host ]] 	box.line.horizontal:rep(user.len), box.t.up,
	--[[ Ts above directory ]] 	box.line.horizontal:rep(workDir.len), box.t.up,
	--[[ corner above git branch ]] box.line.horizontal:rep(gitBranch.len), box.corner.bottomRight,
					chunk.reset, chunk.newl,

	},

	-- line 4, the $
	chunk.concat{
		color[lineColor],
		box.corner.bottomLeft, box.t.left, 
		chunk.new("$ "):color("magenta"), chunk.reset,
	},
}

local columnsLeft = columns - ps1[2].len - 1
table.insert(ps1, 3, box.line.horizontal:rep(columnsLeft) .. box.t.left .. chunk.newl)

ps1 = chunk.concat(ps1)
-- "return" the string to bash
io.write(ps1.str)
