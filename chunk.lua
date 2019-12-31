#!/bin/env lua

local table = require "table"
local string = require "string"

local escapeString = table.concat{"\\[", string.char(27), "[%s\\]"}
local function esc(str)
	return escapeString:format(str)
end
local resetString = esc("0m")

local ANSIColors = {
	black		= "30m",
	red		= "31m",
	green		= "32m",
	yellow		= "33m",
	blue		= "34m",
	magenta		= "35m",
	cyan		= "36m",
	white		= "37m",
	
	lightBlack	= "90m",
	lightRed	= "91m",
	lightGreen	= "92m",
	lightYellow	= "93m",
	lightBlue	= "94m",
	lightMagenta	= "95m",
	lightCyan	= "96m",
	lightWhite	= "97m",
}


local chunk = {}
local __chunk, box, color


function chunk.new(str, len)
	if not len then len = #str end
	return setmetatable({str=str, len=len}, __chunk)
end


__chunk = {
	__metatable = "chunk",
	__concat = function(c1, c2)
		return chunk.new( c1.str .. c2.str, c1.len + c2.len )
	end,
	__tostring = function(self)
		return self.str
	end,
	__index = {
		rep = function(self, num)
			return chunk.new( self.str:rep(num), self.len * num )
		end,
		color = function(self, colorName)
			return chunk.new(esc(ANSIColors[colorName]), 0) .. self .. chunk.new(resetString,0)
		end
	},
	__len = function(self)
		return self.len
	end
}


color = {}
for name, val in pairs(ANSIColors) do
	color[name] = chunk.new( esc(ANSIColors[name]), 0 )
end


box = {
	line = {
		vertical 	= chunk.new("│",1),
		horizontal 	= chunk.new("─",1),
		cross 		= chunk.new("┼",1),
	},
	corner = {
		topLeft 	= chunk.new("┌",1),
		topRight 	= chunk.new("┐",1),
		bottomLeft 	= chunk.new("└",1),
		bottomRight 	= chunk.new("┘",1),
	},
	t = {
		up 		= chunk.new("┴",1),
		down 		= chunk.new("┬",1),
		left 		= chunk.new("┤",1),
		right 		= chunk.new("├",1),
	},
}

function chunk.concat(tab)
	local strTable = {}
	local newLen = 0
	for _, v in ipairs(tab) do
		table.insert(strTable, v.str)
		newLen = newLen + v.len
	end
	return chunk.new(
		table.concat(strTable),
		newLen
	)
end

chunk.newl = chunk.new("\n", 0)
chunk.reset = chunk.new(resetString, 0)
chunk.color = color
chunk.box = box
return chunk
