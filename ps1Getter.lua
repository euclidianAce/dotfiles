#!/bin/env lua

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

-- User/Environment and terminal info
local columns  = tonumber( bashExec("stty size"):gsub("(%d+)%s+(%d+)", "%2"), nil )
local userName = os.getenv("USER")
local env = {
	time		= {str = os.date("%X"), 
			   color = "white"},
	user 		= {str = userName .. "@" .. bashExec("hostname"), 
			   color = "lightRed"},
	workDir 	= {str = bashExec("pwd"):gsub("/home/" .. userName, "~"), 
			   color = "lightBlue"},
	branch 		= {str = bashExec("git branch 2> /dev/null | grep \\*") or "* none", 
			   color = "lightGreen"},
	prompt		= {str = (userName == "root" and "#") or "$",
			   color = (userName == "root" and "red") or "lightMagenta"}
}

env.workDir.str = env.workDir.str .. (" "):rep(10 - #env.workDir.str)
local len = 0
for key in pairs(env) do
	len = len + #env[key].str
	env[key] = chunk.new(env[key].str):color(env[key].color)
end

-- PS1
if 10 + len > columns then -- if terminal is too small for the full thing
	local ps1 = chunk.concat{
		chunk.new(string.char(27).."[1m",0), env.workDir, chunk.reset, chunk.newl, env.prompt, chunk.new(" ")
	}
	io.write(ps1.str)
	return
end
local lineColor = userName == "root" and "lightRed" or "cyan"

local ps1 = {
	chunk.concat{
	-- line 1, the hats to the info

	--[[ Set the lineColor       ]] color[lineColor],
	--[[ Initial Spaces 	     ]] chunk.new(" "):rep(3),
	--[[ Corner and T above time ]] box.corner.topLeft, box.line.horizontal:rep(env.time.len), box.t.down,
	--[[ Ts above user@host      ]] box.line.horizontal:rep(env.user.len), box.t.down,
	--[[ Ts above directory      ]] box.line.horizontal:rep(env.workDir.len), box.t.down,
	--[[ corner above git branch ]] box.line.horizontal:rep(env.branch.len), box.corner.topRight,
					chunk.newl,
	},

	chunk.concat{
		-- line 2, the info and the separators for it
		
		-- initial stuffs
		box.corner.topLeft, box.line.horizontal:rep(2), box.t.left, chunk.reset,
		--   INFO			SEPARATOR
		env.time, 	box.line.vertical:color(lineColor),
		env.user,		box.line.vertical:color(lineColor),
		env.workDir,	box.line.vertical:color(lineColor),
		env.branch,	color[lineColor], box.t.right,
	},

	-- line 3, the bottom bits
	chunk.concat{
	--[[ Set the lineColor       ]] color[lineColor], box.line.vertical,
	--[[ Initial Spaces          ]] chunk.new(" "):rep(2),
	--[[ Corner and T above time ]] box.corner.bottomLeft, box.line.horizontal:rep(env.time.len), box.t.up,
	--[[ Ts above user@host      ]] box.line.horizontal:rep(env.user.len), box.t.up,
	--[[ Ts above directory      ]] box.line.horizontal:rep(env.workDir.len), box.t.up,
	--[[ corner above git branch ]] box.line.horizontal:rep(env.branch.len), box.corner.bottomRight,
					chunk.reset, chunk.newl,

	},

	-- line 4, the $
	chunk.concat{
		color[lineColor],
		box.corner.bottomLeft, box.t.left, 
		env.prompt, chunk.reset, chunk.new(" ")
	},
}

local columnsLeft = columns - ps1[2].len - 1
table.insert(ps1, 3, box.line.horizontal:rep(columnsLeft) .. box.t.left .. chunk.newl)

ps1 = chunk.concat(ps1)
-- "return" the string to bash
io.write(ps1.str)
