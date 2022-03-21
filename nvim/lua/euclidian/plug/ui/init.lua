local nvim = require("euclidian.lib.nvim")
local color = require("euclidian.lib.color")
local dialog = require("euclidian.lib.dialog")
local z = require("euclidian.lib.azync")
local menu = require("euclidian.lib.menu")

local hi = color.scheme.hi
local windowhl = "EuclidianUIWindowHl"
hi[windowhl] = hi.STLNormal

local border = dialog.getDefaultBorder()
for _, v in ipairs(border) do
   v[2] = windowhl
end

local function safeSetOpt(win, name, value)
   vim.schedule(function()
      if win:isValid() then
         win:setOption(name, value)
      end
   end)
end

local function setupWindow(win)
   safeSetOpt(win, "winhighlight", "Normal:" .. windowhl .. ",NormalFloat:" .. windowhl)
end

local function promptDialog(prompt)
   local me = z.currentFrame()
   local ui = nvim.ui()
   local minwid = math.floor(ui.width / 2)
   local maxwid = ui.width - 4
   local d = dialog.new({
      centered = { horizontal = true },
      wid = minwid,
      hei = 1,
      row = -5,
      interactive = true,
      ephemeral = true,
      border = {
         { " ", windowhl },
         { " ", windowhl },
         { " ", windowhl },
         { " ", windowhl },
         { " ", windowhl },
         { " ", windowhl },
         { " ", windowhl },
         { " ", windowhl },
      },
   })
   local result
   local function close()
      d:close()
      z.resume(me)
   end
   d:setPrompt(
   prompt,
   function(res)
      result = res
      close()
   end,
   close)

   local buf = d:buf()
   buf:attach(true, {
      on_lines = function()
         d:fitTextPadded(3, 0, minwid, 1, maxwid, nil):centerHorizontal()
      end,
   })
   setupWindow(d:win())
   buf:setKeymap("n", "<esc>", close)
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
      border = border,
   })
   setupWindow(d:win())
   local function cancel()
      confirm(nil, nil)
      d:close()
   end
   local buf = d:buf()
   buf:setKeymap("n", "<c-c>", cancel, { silent = true })
   buf:setKeymap("n", "<esc>", cancel, { silent = true })
   z.async(menu.new.accordion(accordionItems), d)
end