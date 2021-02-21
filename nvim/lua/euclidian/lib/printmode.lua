
local oldPrint = print
local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")

local Mode = {}




local printmode = {}


local printBuf, printWin
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
      if not printBuf then
         printBuf = nvim.createBuf(false, true)
         printBuf:setLines(0, -1, false, { "=== print buffer ===" })
      end
      if not (printWin and printWin:isValid()) then
         local col, row, wid, hei = dialog.centeredSize(55, nvim.ui().height - 20)
         printWin = nvim.openWin(printBuf, false, {
            relative = "editor",
            style = "minimal",
            col = col + math.floor(nvim.ui().width / 3), row = row, height = hei, width = wid,
         })
      end

      local text = {}
      for i = 1, select("#", ...) do
         local thing = select(i, ...)
         if type(thing) == "string" then
            thing = (thing):gsub("\n", "\\n")
         else
            thing = vim.inspect(thing, inspectOpts)
         end
         table.insert(text, thing)
      end

      vim.schedule(function()
         printBuf:setLines(-1, -1, false, vim.split(table.concat(text, " "), "\n", true))
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

return printmode