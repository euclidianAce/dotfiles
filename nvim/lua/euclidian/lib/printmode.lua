
local oldPrint = print
local dialog = require("euclidian.lib.dialog")

local Mode = {}




local printmode = {}


local printDialog = dialog.new({
   row = 4, col = -65,
   wid = 50, hei = 0.75,
   hidden = true,
})
printDialog:setLines({ "=== print buffer ===" })

local inspectOpts = { newline = " ", indent = "" }

local modes = {
   default = oldPrint,
   custom = oldPrint,
   inspect = function(...)
      local text = {}
      for i = 1, select("#", ...) do
         local obj = select(i, ...)
         if type(obj) == "string" then
            table.insert(text, obj)
         else
            table.insert(text, vim.inspect(obj, inspectOpts))
         end
      end
      oldPrint(table.concat(text, " "))
   end,
   buffer = function(...)
      local args = { n = select("#", ...), ... }
      vim.schedule(function()
         printDialog:show()

         local text = {}
         for i = 1, args.n do
            local thing = args[i]
            if type(thing) == "string" then
               thing = thing:gsub("\n", "\\n")
            else
               thing = vim.inspect(thing, inspectOpts)
            end
            table.insert(text, thing)
         end

         printDialog:appendLines(vim.split(table.concat(text, " "), "\n", true))
      end)
   end,
}

local currentMode = "default"

function printmode.print(...)
   modes[currentMode](...)
end

function printmode.printfn(mode)
   return modes[mode or currentMode]
end

function printmode.clearBuffer()
   vim.schedule(function()
      printDialog:setLines({ "=== print buffer ===" })
   end)
end

function printmode.set(newMode)
   currentMode = newMode
   return printmode
end

function printmode.custom(fn)
   modes.custom = fn
   return printmode
end

function printmode.override()
   _G["print"] = printmode.print
   return printmode
end

function printmode.restore()
   _G["print"] = oldPrint
   return printmode
end

function printmode.default()
   return oldPrint
end

return printmode