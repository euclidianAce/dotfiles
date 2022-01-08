local dialog = require("euclidian.lib.dialog")
local input = require("euclidian.lib.input")
local nvim = require("euclidian.lib.nvim")
local z = require("euclidian.lib.azync")
local quick = {}

local Dialog = dialog.Dialog
local Opts = dialog.Dialog.Opts

function quick.prompt(txt, opts, onOpen)
   local res
   local me = assert(z.currentFrame())
   local originalWindow = nvim.Window()
   local d = dialog.new(opts or {
      wid = 45, hei = 1,
      centered = true,
      interactive = true,
      ephemeral = true,
   })
   local function close()
      d:close()
      z.resume(me)
   end
   d:ensureWin():setVar("QuickDialog", true)
   d:ensureBuf():attach(false, {
      on_lines = function()
         d:fitTextPadded(1, 0, 45, nil, nil, 1):centerHorizontal()
      end,
   })
   d:addKeymap(
   "n", "<esc>",
   close,
   { silent = true })

   d:setPrompt(
   txt,
   function(result)
      res = result
      if originalWindow:isValid() then
         nvim.api.setCurrentWin(originalWindow.id)
      end
      close()
   end,
   close)

   if onOpen then vim.schedule_wrap(function() onOpen(d) end) end
   z.suspend()
   return res
end

function quick.yesOrNo(pre, affirm, deny, opts)
   local origId = nvim.Window().id
   local d = dialog.new(opts or {
      wid = 45, hei = 3,
      centered = true,
      interactive = true,
      ephemeral = true,
   })
   d:ensureWin():setVar("QuickDialog", true)
   affirm = affirm or "Yes"
   deny = deny or "No"
   d:setLines({
      pre,
      affirm,
      deny,
   }):fitTextPadded(2, 1, 45, 3):center()
   d:win():setOption("cursorline", true)
   local ln
   repeat
      input.waitForKey(d:buf(), "n", "<cr>")
      ln = d:getCursor()
   until ln > 1
   nvim.api.setCurrentWin(origId)
   d:close()
   return ln == 2
end

return quick