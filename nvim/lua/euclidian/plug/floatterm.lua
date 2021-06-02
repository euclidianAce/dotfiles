
local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
local a = vim.api

local key = ""
local Dialog = dialog.Dialog
local floatterm = {SetupOpts = {}, }















local d
local openTerm
local hideTerm

local function addMappings()
   if d:win():isValid() then

      d:ensureBuf():setKeymap("n", key, hideTerm, { noremap = true, silent = true })
      d:ensureBuf():setKeymap("t", key, hideTerm, { noremap = true, silent = true })
      nvim.autocmd("WinLeave", nil, hideTerm, { buffer = d:ensureBuf().id })
   else

      nvim.setKeymap("n", key, openTerm, { noremap = true, silent = true })
   end
end

local getBuf

openTerm = function()
   getBuf()
   d:show():win():setOption("winblend", 8)
   addMappings()
end

hideTerm = function()
   d:hide()
   addMappings()
end

getBuf = function()
   local buf = d:ensureBuf()
   buf:setOption("modified", false)
   if buf:getOption("buftype") ~= "terminal" then
      buf:call(function() vim.fn.termopen("bash") end)
   end
   addMappings()
   return d:buf()
end

function floatterm.channel()
   return getBuf():getOption("channel")
end

local chansend = a.nvim_chan_send

function floatterm.send(s)
   local buf = getBuf()
   if not buf:isValid() then
      return false
   end
   local channel = buf:getOption("channel")
   chansend(channel, s)
   return true
end

return setmetatable(floatterm, {
   __call = function(self, opts)
      opts = opts or {}

      if d then
         d:close()
         d = nil
      end

      d = dialog.new({
         wid = opts.wid or 0.9, hei = opts.hei or 0.85,
         row = opts.row, col = opts.col,
         centered = opts.centered or true,
         border = opts.border,

         interactive = true,
         hidden = true,
      })

      addMappings()

      nvim.newCommand({
         name = "FloatingTerminal",
         body = openTerm,
         nargs = 0,
         bar = true,
         overwrite = true,
      })

      nvim.newCommand({
         name = "FloatingTerminalSend",
         body = function(...)
            local buf = getBuf()
            local channel = buf:getOption("channel")
            chansend(channel, table.concat({ ... }, " "))
            chansend(channel, "\n")
         end,
         nargs = "+",
         overwrite = true,
      })

      return self
   end,
})