
local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
local a = vim.api

local key = ""
local shell = vim.fn.has("win32") and "powershell.exe" or "bash"
local termopenOpts = {}
local Dialog = dialog.Dialog
local floatterm = {SetupOpts = {}, }


















local d
local openTerm
local hideTerm

function floatterm.open()
   openTerm()
end

function floatterm.hide()
   hideTerm()
end

function floatterm.buffer()
   return d:ensureBuf()
end

local function addShowMappings()
   nvim.setKeymap("n", key, openTerm, { noremap = true, silent = true })
end

local function addHideMappings()
   local b = d:ensureBuf()
   b:setKeymap("n", key, hideTerm, { noremap = true, silent = true })
   b:setKeymap("t", key, hideTerm, { noremap = true, silent = true })
   nvim.autocmd("WinLeave", nil, hideTerm, { buffer = b.id, once = true })
end

local getBuf

do
   local shown = false
   openTerm = function()
      shown = true
      getBuf()
      d:show():win():setOption("winblend", 8)
      d:focus()
   end

   hideTerm = function()
      if shown then
         shown = false
         d:hide()
         addShowMappings()
      end
   end
end

local channelId

getBuf = function()
   local buf = d:ensureBuf()
   if buf:getOption("buftype") ~= "terminal" then
      buf:setOption("modified", false)
      buf:call(function()
         channelId = vim.fn.termopen(shell, termopenOpts)







      end)
      addHideMappings()
   end
   return buf
end


function floatterm.channel()
   return channelId
end

local chansend = a.nvim_chan_send

function floatterm.send(s)
   local buf = getBuf()
   if not buf:isValid() then
      return false
   end
   chansend(channelId, s)
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
         name = "FloatingTerminalShow",
         body = openTerm,
         nargs = 0,
         bar = true,
         overwrite = true,
      })

      nvim.newCommand({
         name = "FloatingTerminalHide",
         body = hideTerm,
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