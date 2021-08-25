
local dialog = require("euclidian.lib.dialog")

local Dialog = dialog.Dialog

local Opts = {}



local notification = {
   Opts = Opts,
}

local Container = {}




local stack = {}

local function longestLen(arr)
   local l = 0
   for _, v in ipairs(arr) do
      if #v > l then l = #v end
   end
   return l
end

local function shift(d, n)
   if n == 0 then return end
   local win = d:win()
   local c = win:getConfig()
   c.row = (c.row)[false] + n
   win:setConfig(c)
end

local borderOffset = 2

local function dismiss(c)
   local height = c.d:win():getHeight() + borderOffset
   c.d:close()
   table.remove(stack, c.idx)
   for i = c.idx, #stack do
      stack[i].idx = i
      shift(stack[i].d, height)
   end
end

local function insert(d)
   local c = {
      d = d,
      idx = 1,
   }
   local height = d:win():getHeight() + borderOffset
   table.insert(stack, 1, c)
   for i = 2, #stack do
      stack[i].idx = i
      shift(stack[i].d, -height)
   end
   return c
end

function notification.create(str, opts)
   opts = opts or {}
   local msTimeout = opts.msTimeout or 2500

   local lines = vim.split(str, "\n")
   local len = longestLen(lines)

   local dOpts = {
      row = -#lines - 5, col = -4 - len,
      wid = len, hei = #lines,
      interactive = false,
   }

   local d = dialog.new(dOpts)
   d:setLines(lines)
   local c = insert(d)

   vim.defer_fn(function()
      dismiss(c)
   end, msTimeout)
end

return notification