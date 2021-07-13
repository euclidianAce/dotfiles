
local dialog = require("euclidian.lib.dialog")

local z = require("euclidian.lib.async.zig")



local Menu = {}









local menu = {
   Menu = Menu,
}

function menu.new(kind)
   return setmetatable({ kind = kind, items = {} }, { __index = Menu })
end

function Menu:add(item)
   table.insert(self.items, item)
   return self
end

function Menu:step(opts)
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

   assert(self.kind == "accordion")

   local State = {}



   local states = {}
   local function appendItem(lines, item, indent)
      local len = #lines + 1
      if type(item) == "string" then
         lines[len] = ("  "):rep(indent) .. item
      else
         lines[len] = ("  "):rep(indent) .. item[1]
         if not states[item] then
            states[item] = { enabled = false }
         end
         local s = states[item]
         s.line = len
         if s.enabled then
            appendItem(lines, item[2], indent + 1)
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

   local function iter()
      renderMenu()
      local pressed = waitForKey("<cr>", "<bs>")
      if pressed == "<cr>" then
         local row = d:getCursor()
         for item, state in pairs(states) do
            if state.line == row and type(item) == "string" then
               d:close()
               return item
            end
         end
         return ""
      elseif pressed == "<bs>" then
         d:close()
         return
      end
   end
   return iter
end

return menu