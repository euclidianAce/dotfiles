local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
local floatterm = require("euclidian.plug.floatterm.api")
local Dialog = dialog.Dialog

local key = ""
local shell = vim.fn.has("win32") and "powershell.exe" or "bash"
local termopenOpts = {}

local SetupOpts = {}














return function(opts)
   opts = opts or {}

   floatterm.setToggleKey(opts.toggle or key)
   floatterm.setShell(opts.shell or shell)
   floatterm.setTermOptions(opts.termopenOpts or termopenOpts)

   floatterm.deinit()
   floatterm.init({
      wid = opts.wid or 0.9, hei = opts.hei or 0.85,
      row = opts.row, col = opts.col,
      centered = opts.centered or true,
      border = opts.border,

      interactive = true,
      hidden = true,
   })

   nvim.newCommand({
      name = "FloatingTerminalShow",
      body = floatterm.show,
      nargs = 0,
      bar = true,
      overwrite = true,
   })

   nvim.newCommand({
      name = "FloatingTerminalHide",
      body = floatterm.hide,
      nargs = 0,
      bar = true,
      overwrite = true,
   })

   nvim.newCommand({
      name = "FloatingTerminalSend",
      body = function(...)
         floatterm.send(table.concat({ ... }, " ") .. "\n")
      end,
      nargs = "+",
      overwrite = true,
   })
end