
local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
local a = vim.api

local key = ""
local shell = "bash"
local termopenOpts = {}
local Dialog = dialog.Dialog
local floatterm = {SetupOpts = {}, }


















local d
local openTerm
local hideTerm

local function addShowMappings()
   nvim.setKeymap("n", key, openTerm, { noremap = true, silent = true })
end

local function addHideMappings()
   d:ensureBuf():setKeymap("n", key, hideTerm, { noremap = true, silent = true })
   d:ensureBuf():setKeymap("t", key, hideTerm, { noremap = true, silent = true })
   nvim.autocmd("WinLeave", nil, hideTerm, { buffer = d:ensureBuf().id, once = true })
end

local getBuf

do
   local shown = false
   openTerm = function()
      shown = true
      getBuf()
      d:show():win():setOption("winblend", 8)
   end

   hideTerm = function()
      if shown then
         shown = false
         d:hide()
         addShowMappings()
      end
   end
end

getBuf = function()
   local buf = d:ensureBuf()
   if buf:getOption("buftype") ~= "terminal" then
      buf:setOption("modified", false)
      buf:call(function()
         vim.fn.termopen(shell, termopenOpts)
      end)
      addHideMappings()
   end
   return buf
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
      key = opts.toggle or key
      shell = opts.shell or shell
      termopenOpts = opts.termopenOpts or termopenOpts

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

      addShowMappings()

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