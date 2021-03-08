
local oldPrint <const> = print
local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")

local enum Mode
	"buffer" "inspect"
	"default" "custom"
end

local record printmode
end

local printBuf, printWin: nvim.Buffer, nvim.Window
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
		local args = { n = select("#", ...), ... }
		vim.schedule(function()
			if not printBuf then
				printBuf = nvim.createBuf(false, true)
				printBuf:setLines(0, -1, false, { "=== print buffer ===" })
			end
			if not (printWin and printWin:isValid()) then
				local col <const>, row <const>, wid <const>, hei <const> = dialog.centeredSize(55, nvim.ui().height - 20)
				printWin = nvim.openWin(printBuf, false, {
					relative = "editor",
					style = "minimal",
					col = col + nvim.ui().width // 3, row = row,
					height = hei, width = wid,
				})
			end

			local text <const> = {}
			for i = 1, args.n do
				local thing = args[i]
				if type(thing) == "string" then
					thing = (thing as string):gsub("\n", "\\n")
				else
					thing = vim.inspect(thing, inspectOpts)
				end
				table.insert(text, thing as string)
			end

			printBuf:setLines(-1, -1, false, vim.split(table.concat(text, " "), "\n", true))
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

function printmode.default(): function(...: any)
	return oldPrint
end

return printmode

