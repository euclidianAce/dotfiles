#!/bin/env lua
-- Some utility functions for getting system info like battery and RAM usage

local sys = {
	memory 	= {},
	battery = {},
}

-- helper functions

-- if the file exists, it opens it and returns a handle to it
-- otherwise returns false
local function file_exists(path)
	local file = io.open(path)
	if not file then return false end
	return file
end

-- get the stdout of a command
local function exec(command)
	local cmd = io.popen(command)
	if not cmd then return false end
	local stdout = cmd:read()
	cmd:close()
	return stdout
end


function sys.battery.get_max_charge()
	local battery_file = file_exists( "/sys/class/power_supply/BAT0/charge_full" )
	if not battery_file then return false end
	local charge = battery_file:read()
	battery_file:close()
	return tonumber(charge)
end

function sys.battery.get_current_charge()
	local battery_file = file_exists( "/sys/class/power_supply/BAT0/charge_now" )
	if not battery_file then return false end
	local charge = battery_file:read()
	battery_file:close()
	return tonumber(charge)
end

function sys.battery.get_percent()
	local max_charge = sys.battery.get_max_charge()
	if not max_charge then return false end
	local current_charge = sys.battery.get_current_charge()
	if not current_charge then return false end

	return current_charge / max_charge
end

function sys.memory.get_info()
	-- uses the `free` command
	-- example output:
	-- 	total		used		free		shared		buff/cache		available
	-- Mem:	 8291		7583		1293		     0		       109		     3271
	-- Swap: 1029		   0		1029
	
	local stdout = exec("free | grep Mem:")
	if not stdout then return false end

	local info = {}
	local names = {"total", "used", "free", "shared", "cache", "available"}
	
	for num in stdout:gmatch("%d+") do
		if #names == 0 then break end
		info[ table.remove(names, 1) ] = tonumber(num)
	end
	
	return info
end



return sys

