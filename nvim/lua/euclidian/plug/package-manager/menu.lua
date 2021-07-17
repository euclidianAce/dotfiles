
local dialog = require("euclidian.lib.dialog")

local z = require("euclidian.lib.async.zig")



local Accordion = {}







local new = {}

function new.accordion(items)
   return setmetatable({
      items = items,
      item_prefix = "* ",
      expanded_prefix = "v ",
      unexpanded_prefix = "> ",
   }, { __index = Accordion })
end

local menu = {
   Accordion = Accordion,
   new = new,
}


function Accordion:run(opts)
   local d = dialog.new(opts)
   local function waitForKey(...)
      local keys = { ... }
      local function delKeymaps()
         for _, key in ipairs(keys) do
            d:delKeymap("n", key)
         end
      end
      local me = assert(z.currentFrame(), "attempt to waitForKey not in a coroutine")
      local pressed
      z.suspend(vim.schedule_wrap(function()
         local keyopts = { noremap = true, silent = true }
         for _, key in ipairs(keys) do
            d:addKeymap("n", key, function()
               pressed = key
               delKeymaps()
               z.resume(me)
            end, keyopts)
         end
      end))
      return pressed
   end

   local State = {}



   local states = {}
   local function appendItem(lines, item, indent)
      local len = #lines + 1
      local second = item[2]
      if not states[item] then
         states[item] = { enabled = false }
      end
      local s = states[item]
      s.line = len
      lines[len] = ("  "):rep(indent) ..
      (type(second) == "function" and self.item_prefix or
      s.enabled and self.expanded_prefix or
      self.unexpanded_prefix) ..
      item[1]
      if type(second) == "table" and s.enabled then
         for _, child in ipairs(second) do
            appendItem(lines, child, indent + 1)
         end
      end
   end
   local function renderMenu()
      local lines = {}
      for _, item in ipairs(self.items) do
         appendItem(lines, item, 0)
      end
      d:setLines(lines)
   end

   while true do
      renderMenu()
      local pressed = waitForKey("<cr>", "<tab>", "<bs>")
      if pressed == "<cr>" or pressed == "<tab>" then
         local row = d:getCursor()
         for item, state in pairs(states) do
            local second = item[2]
            if state.line == row then
               if type(second) == "function" and pressed == "<cr>" then
                  d:close()
                  second()
                  return
               else
                  state.enabled = not state.enabled
               end
            end
         end
      elseif pressed == "<bs>" then
         d:close()
         return
      end
   end
end

return menu