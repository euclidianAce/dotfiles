local dialog = require("euclidian.lib.dialog")
local input = require("euclidian.lib.input")
local nvim = require("euclidian.lib.nvim")

local ns = nvim.api.createNamespace("euclidian.lib.menu")



local Accordion = {Options = {}, }














local Modifiable = {Item = {}, }











local Checklist = {}








local new = {}
local accordionMt = { __index = Accordion }

function new.accordion(items)
   return setmetatable({
      items = items,
      item_prefix = "* ",
      expanded_prefix = "- ",
      unexpanded_prefix = "+ ",
   }, accordionMt)
end

local modifiableMt = { __index = Modifiable }

function new.modifiable(items)
   return setmetatable({
      items = items,
   }, modifiableMt)
end

local checklistMt = { __index = Checklist }

function new.checklist(items)
   return setmetatable({
      items = items,
      checked_prefix = "[*] ",
      unchecked_prefix = "[ ] ",
   }, checklistMt)
end

local menu = {
   Accordion = Accordion,
   Modifiable = Modifiable,
   Checklist = Checklist,
   new = new,
}

function accordionMt.__call(self, d, opts)
   opts = opts or {}

   local buf = d:buf()
   local win = d:win()

   local State = {}



   local states = {}
   local lines = {}
   local function renderMenu()
      local extmarks = {}

      local function appendItem(item, indent)
         local len = #lines + 1
         if type(item) == "string" then
            lines[len] = ("  "):rep(indent) .. item
         else
            local second = item[2]
            if not states[item] then
               states[item] = { enabled = false }
            end
            local s = states[item]
            s.line = len
            local prefix = ""
            local hl = "Normal"
            if type(second) == "function" then
               prefix = self.item_prefix
               hl = "Type"
            elseif second then
               prefix = s.enabled and
               self.expanded_prefix or
               self.unexpanded_prefix
               hl = "Special"
            end
            lines[len] = ("  "):rep(indent) .. prefix .. item[1]
            table.insert(
            extmarks,
            { len - 1, indent * 2, {
               end_row = len - 1,
               end_col = #lines[len],
               hl_group = hl,
            }, })

            if type(second) == "table" and s.enabled then
               for _, child in ipairs(second) do
                  appendItem(child, indent + 1)
               end
            end
         end
      end

      buf:clearNamespace(ns, 0, -1)
      lines = {}
      for _, state in pairs(states) do
         state.line = -1
      end
      for _, item in ipairs(self.items) do
         appendItem(item, 0)
      end
      d:setLines(lines)
      vim.schedule(function()
         for _, mark in ipairs(extmarks) do
            buf:setExtmark(ns, mark[1], mark[2], mark[3])
         end
      end)
   end

   self.redraw = renderMenu

   win:setOption("winhl", win:getOption("winhl"))
   win:setOption("cursorline", true)

   repeat
      renderMenu()
      local pressed = input.waitForKey(d:buf(), "n", "<cr>", "<tab>", "<bs>", "<2-LeftMouse>")

      if pressed == "<cr>" or pressed == "<tab>" or pressed == "<2-LeftMouse>" then
         local row = d:getCursor()
         for item, state in pairs(states) do
            if not (type(item) == "string") then
               local second = item[2]
               if state.line == row then
                  if type(second) == "function" and (pressed == "<cr>" or pressed == "<2-LeftMouse>") then
                     if opts.persist then
                        second()
                     else
                        d:close()
                        self.redraw = nil
                        return second()
                     end
                  else
                     state.enabled = not state.enabled
                  end
               end
            end
         end
      end
   until pressed == "<bs>"
   d:close()
   self.redraw = nil
end

function modifiableMt.__call(self, d)
   local function render()
      local lines = {}
      for i, item in ipairs(self.items) do
         lines[i] = item.name .. ": " .. tostring(item.value)
      end
      d:setLines(lines)
   end

   repeat
      render()
      local pressed = input.waitForKey(d:buf(), "n", "<cr>", "<bs>")
      if pressed == "<cr>" then
         d:focus()
         local row = d:getCursor()
         local item = self.items[row]
         local val
         repeat
            val = input.input({ prompt = "New Value for " .. item.name .. ": " })
            local ok = true
            if not rawequal(val, nil) then
               local err
               ok, err = item.validator(val)
               if ok then
                  item.value = val
               else
                  nvim.api.errWriteln(
                  ("Invalid input for item %q: %s"):format(
                  item.name,
                  assert(err, "no error message was returned from the validator")))


               end
            end
         until ok
      elseif pressed == "<bs>" then
         break
      end
   until pressed == "<bs>"

   d:close()
end

function checklistMt.__call(self, d)
   local function render()
      local lines = {}
      for i, item in ipairs(self.items) do
         if type(item) == "string" then
            lines[i] = self.unchecked_prefix .. item
         else
            lines[i] = (item[2] and self.checked_prefix or self.unchecked_prefix) .. item[1]
         end
      end
      d:setLines(lines)
   end

   local function toggleItem(i)
      if type(self.items[i]) == "string" then
         self.items[i] = { self.items[i], true }
      else
         (self.items[i])[2] = not (self.items[i])[2]
      end
   end

   repeat
      render()
      local pressed = input.waitForKey(d:buf(), "n", "<cr>", "<tab>", "<bs>", "<c-y>")
      if pressed == "<cr>" or pressed == "<tab>" then
         toggleItem((d:getCursor()))
      elseif pressed == "<c-y>" then
         local ret = {}
         for _, v in ipairs(self.items) do
            if type(v) == "table" and v[2] then
               table.insert(ret, v[1])
            end
         end
         return ret
      end
   until pressed == "<bs>"
end

return menu