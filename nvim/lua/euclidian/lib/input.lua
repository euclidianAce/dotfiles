local nvim = require("euclidian.lib.nvim")
local z = require("euclidian.lib.azync")

local input = {}

function input.waitForKey(buf, mode, ...)
   local keys = { ... }
   local teardown = vim.schedule_wrap(function()
      for _, key in ipairs(keys) do
         buf:delKeymap(mode, key)
      end
   end)
   local pressed
   local me = assert(z.currentFrame(), "attempt to waitForKey not in a coroutine")
   vim.schedule(function()
      for _, key in ipairs(keys) do
         buf:setKeymap(mode, key, function()
            pressed = key
            teardown()
            z.resume(me)
         end, { silent = true })
      end
   end)
   z.suspend()
   return pressed
end

return input