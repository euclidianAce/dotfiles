
local a <const> = vim.api
local oldPrint <const> = print
local window <const> = require("euclidian.lib.window")

local enum Mode
	"buffer" "inspect"
	"default" "custom"
end

local record printmode
end

local printBuf, printWin: window.BufId, window.WinId
local inspectOpts <const> = { newline = " ", indent = "" }

local modes <const>: {Mode:function(...:any)} = {
	default = oldPrint,
	custom = oldPrint,
	inspect = function(...: any)
		local text: {string} = {}
		for i = 1, select("#", ...) do
			local obj <const> = select(i, ...)
			if type(obj) == "string" then
				table.insert(text, obj as string)
			else
				table.insert(text, vim.inspect(obj, inspectOpts))
			end
		end
		oldPrint(table.concat(text, " "))
	end,
	buffer = function(...: any)
		if not printBuf then
			printBuf = a.nvim_create_buf(false, true) as window.BufId
			a.nvim_buf_set_lines(printBuf, 0, -1, false, { "=== print buffer ===" })
		end
		if not (printWin and a.nvim_win_is_valid(printWin)) then
			printWin = window.floating(-75, 2, 64, 45, printBuf)
		end

		local text <const> = {}
		for i = 1, select("#", ...) do
			local thing = select(i, ...)
			if type(thing) == "string" then
				thing = (thing as string):gsub("\n", "\\n")
			else
				thing = vim.inspect(thing, inspectOpts)
			end
			table.insert(text, thing as string)
		end

		vim.schedule(function()
			a.nvim_buf_set_lines(printBuf, -1, -1, false, vim.split(table.concat(text, " "), "\n", true))
		end)
	end,
}

local currentMode: Mode = "default"

function printmode.print(...: any)
	modes[currentMode](...)
end

function printmode.printfn(mode: Mode): function(...: any)
	return modes[mode or currentMode]
end

function printmode.set(newMode: Mode): printmode
	currentMode = newMode
	return printmode
end

function printmode.custom(fn: function(...: any)): printmode
	modes.custom = fn
	return printmode
end

function printmode.override(): printmode
	_G["print"] = printmode.print
	return printmode
end

function printmode.restore(): printmode
	_G["print"] = oldPrint
	return printmode
end

return printmode

