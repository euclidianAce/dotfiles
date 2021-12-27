local a = vim.api
local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
local z = require("euclidian.lib.azync")
local quick = {}

local Dialog = dialog.Dialog
local Opts = dialog.Dialog.Opts

function quick.prompt(txt, opts, onOpen)
   local originalWindow = nvim.Window()
   local d = dialog.new(opts or {
      wid = 45, hei = 1,
      centered = true,
      interactive = true,
      ephemeral = true,
   })
   d:ensureWin():setVar("QuickDialog", true)
   d:ensureBuf():attach(false, {
      on_lines = function()
         d:fitTextPadded(1, 0, 45, nil, nil, 1):centerHorizontal()
      end,
   })
   if onOpen then
      onOpen(d)
   end
   local res
   z.suspend(function(me)
      local function close()
         d:close()
         z.resume(me)
      end
      d:addKeymap(
      "n", "<esc>",
      close,
      { silent = true, noremap = true })

      d:setPrompt(
      txt,
      function(result)
         res = result
         if originalWindow:isValid() then
            a.nvim_set_current_win(originalWindow.id)
         end
         close()
      end,
      close)

   end)
   return res
end

local function waitForKey(d, ...)
   local keys = { ... }
   local function delKeymaps()
      vim.schedule(function()
         for _, key in ipairs(keys) do
            d:delKeymap("n", key)
         end
      end)
   end
   local pressed
   local me = assert(z.currentFrame(), "attempt to waitForKey not in a coroutine")
   vim.schedule(function()
      for _, key in ipairs(keys) do
         d:addKeymap("n", key, function()
            pressed = key
            delKeymaps()
            z.resume(me)
         end, { noremap = true, silent = true })
      end
   end)
   z.suspend()
   return pressed
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
      waitForKey(d, "<cr>")
      ln = d:getCursor()
   until ln > 1
   a.nvim_set_current_win(origId)
   d:close()
   return ln == 2
end


return quick