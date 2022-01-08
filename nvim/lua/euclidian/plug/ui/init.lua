local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
local z = require("euclidian.lib.azync")
local menu = require("euclidian.lib.menu")

local function wait(ms)
   z.suspend(function(me)
      vim.defer_fn(function() z.resume(me) end, ms)
   end)
end

local function flashWindow(win)
   local orig = win:getOption("winhighlight")
   z.async(function()
      for _ = 1, 3 do
         vim.schedule(function()
            if win:isValid() then
               win:setOption("winhighlight", "Normal:STLNormal,NormalFloat:STLInsert")
            end
         end)
         wait(250)
         vim.schedule(function()
            if win:isValid() then
               win:setOption("winhighlight", orig)
            end
         end)
         wait(150)
      end
   end)
end

local function promptDialog(prompt)
   local me = z.currentFrame()
   local minwid = #prompt + 10
   local d = dialog.new({
      centered = { horizontal = true },
      wid = minwid,
      hei = 1,
      row = -1,
      interactive = true,
      ephemeral = true,
      border = "none",
   })
   local result
   d:setPrompt(
   prompt,
   function(res)
      result = res
      d:close()
      z.resume(me)
   end,
   function()
      d:close()
      z.resume(me)
   end)

   d:buf():attach(true, {
      on_lines = function()
         d:fitTextPadded(10, 0, minwid, 1, nil, nil):centerHorizontal()
      end,
   })
   flashWindow(d:win())
   vim.schedule(function() nvim.command("startinsert") end)
   z.suspend()
   return result
end

vim.ui.input = function(opts, confirm)
   assert(confirm)
   z.async(function()
      local res = promptDialog(opts.prompt)
      if res then
         confirm(res)
      end
   end)
end

local function clamp(n, a, b)
   return math.min(math.max(n, a), b)
end

vim.ui.select = function(items, opts, confirm)
   assert(confirm)
   local inspector = opts.format_item or tostring

   local accordionItems = {
      { opts.prompt or "Select one of:" },
   }

   local longest = 0
   for i, v in ipairs(items) do
      local str = inspector(v) or "<???>"
      if #str > longest then
         longest = #str
      end
      accordionItems[i + 1] = { str, function() confirm(v, i) end }
   end

   local hei = clamp(#accordionItems, 4, math.floor(nvim.ui().height / 4))
   local d = dialog.new({
      centered = { horizontal = true },
      interactive = true,
      ephemeral = true,
      wid = clamp(longest + 5, 20, math.floor(nvim.ui().width / 2)),
      hei = hei,
      row = -hei - 4,
      border = "none",
   })
   flashWindow(d:win())
   local function cancel()
      confirm(nil, nil)
      d:close()
   end
   local buf = d:buf()
   buf:setKeymap("n", "<c-c>", cancel, { silent = true })
   buf:setKeymap("n", "<esc>", cancel, { silent = true })
   z.async(menu.new.accordion(accordionItems), d)
end