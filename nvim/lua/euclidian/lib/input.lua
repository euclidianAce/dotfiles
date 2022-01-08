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

function input.input(opts)
   local result
   z.suspend(function(me)
      vim.ui.input(opts, function(i)
         result = i
         z.resume(me)
      end)
   end)
   return result
end

function input.select(items, opts)
   local result, result_idx
   z.suspend(function(me)
      vim.ui.select(items, opts, function(r, i)
         result = r
         result_idx = i
         z.resume(me)
      end)
   end)
   return result, result_idx
end

return input