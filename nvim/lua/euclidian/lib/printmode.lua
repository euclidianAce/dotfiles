
local a = vim.api
local oldPrint = print
local window = require("euclidian.lib.window")

local Mode = {}




local printmode = {}


local inspectOpts = { newline = " ", indent = "" }
local printBuf = a.nvim_create_buf(false, true)
a.nvim_buf_set_lines(printBuf, 0, -1, false, { "=== print buffer ===" })
local printWin
local modes = {
   default = oldPrint,
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
      if not printWin or not a.nvim_win_is_valid(printWin) then
         printWin = window.floating(-75, 2, 64, 45, printBuf)
      end

      local text = {}
      for i = 1, select("#", ...) do
         local thing = select(i, ...)
         if type(thing) == "string" then
            thing = thing:gsub("\n", "\\n")
         else
            thing = vim.inspect(thing, inspectOpts)
         end
         table.insert(text, thing)
      end

      vim.schedule(function()
         a.nvim_buf_set_lines(printBuf, -1, -1, false, vim.split(table.concat(text, " "), "\n", true))
      end)
   end,
}

local currentMode = "default"

function printmode.set(newMode)
   currentMode = newMode
   return printmode
end

function printmode.print(...)
   modes[currentMode](...)
end

function printmode.printfn(mode)
   return modes[mode or currentMode]
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
