
local oldPrint <const> = print
local dialog <const> = require("euclidian.lib.dialog")

local enum Mode
	"buffer" "inspect"
	"default" "custom"
end

local record printmode
end

local printDialog <const> = dialog.new{
	centered = true,
	wid = 50, hei = 0.75,
	hidden = true,
}
printDialog:setLines{"=== print buffer ==="}

local inspectOpts <const> = { newline = " ", indent = "" }

local modes <const>: {Mode:function(...:any)} = {
	default = oldPrint,
	custom = oldPrint,
	inspect = function(...: any)
		local text: {string} = {}
		for i = 1, select("#", ...) do
			local obj <const> = select(i, ...)
			if obj is string then
				table.insert(text, obj)
			else
				table.insert(text, vim.inspect(obj, inspectOpts))
			end
		end
		oldPrint(table.concat(text, " "))
	end,
	buffer = function(...: any)
		local args = { n = select("#", ...), ... }
		vim.schedule(function()
			printDialog:show()

			local text <const> = {}
			for i = 1, args.n do
				local thing = args[i]
				if thing is string then
					thing = thing:gsub("\n", "\\n")
				else
					thing = vim.inspect(thing, inspectOpts)
				end
				table.insert(text, thing as string)
			end

			printDialog:appendLines(vim.split(table.concat(text, " "), "\n", true))
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

function printmode.clearBuffer()
	vim.schedule(function()
		printDialog:setLines{"=== print buffer ==="}
	end)
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
