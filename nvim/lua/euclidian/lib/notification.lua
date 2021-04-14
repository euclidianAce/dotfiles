
local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")

local Dialog = dialog.Dialog

local Opts = {}



local notification = {
   Opts = Opts,
}

local function longestLen(arr)
   local l = 0
   for _, v in ipairs(arr) do
      if #v > l then l = #v end
   end
   return l
end

local Node = {}



local root = {}

local function lastNode()
   local n = root
   while n.next do
      n = n.next
   end
   return n
end

local function insert(d)
   lastNode().next = { d = d }
end

local function moveDown(d, n)
   if n > 0 then
      local c = d.win:getConfig()
      c.row = (c.row)[false] + n
      d.win:setConfig(c)
   end
end

local borderOffset = 3

local function dismiss(d)
   local n = root
   local prev
   while n and n.d ~= d do
      prev = n
      n = n.next
   end

   prev.next = n.next
   local acc = 0

   if n.d then
      acc = n.d.win:getHeight() + borderOffset
      n.d:close()
   end
   n = n.next

   while n do
      moveDown(n.d, acc)
      n = n.next
   end
end

function notification.create(txt, opts)
   local msTimeout = opts and opts.msTimeout or 2500

   local lines = vim.split(txt, "\n")
   local len = longestLen(lines)

   local uiHeight = nvim.ui().height
   local dOpts = {
      row = uiHeight - #lines - 5, col = -4 - len,
      wid = len, hei = #lines,
      interactive = false,
   }

   local n = lastNode()
   if n.d then
      local conf = n.d.win:getConfig()
      dOpts.row = (conf.row)[false] - dOpts.hei - borderOffset
   end

   local d = dialog.new(dOpts)
   d:setLines(lines)
   insert(d)

   vim.defer_fn(function()
      dismiss(d)
   end, msTimeout)
end

return notification