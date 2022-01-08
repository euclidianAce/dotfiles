local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
local z = require("euclidian.lib.azync")
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

local function waitForKey(d, ...)
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
      local pressed = waitForKey(d, "<cr>", "<tab>", "<bs>", "<2-LeftMouse>")

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

local function longestLength(arr)
   local longest = 0
   for _, v in ipairs(arr) do
      local len = #(v)
      if len > longest then
         longest = len
      end
   end
   return longest
end

function modifiableMt.__call(self, d)
   local function render()
      local lines = {}
      for i, item in ipairs(self.items) do
         lines[i] = item.name .. ": " .. tostring(item.value)
      end
      d:setLines(lines)
   end

   local function editDialog(item, resume)
      local editor = dialog.new({
         wid = 1,
         hei = 1,
         centered = true,
         interactive = true,
         ephemeral = true,
      })
      local lines = {
         "(Name): " .. item.name,
         "(Old Value): " .. tostring(item.value),
      }
      local width = longestLength(lines) + 10
      editor:setLines(lines)
      editor:buf():attach(false, {
         on_lines = function()
            editor:fitTextPadded(1, 0, width, 3, nil, nil):centerHorizontal()
         end,
      })
      editor:fitText(width, 2):centerHorizontal()
      local close = vim.schedule_wrap(function()
         nvim.command("stopinsert")
         editor:close()
         z.resume(resume)
      end)
      local function accept(input)
         item.value = input
         close()
      end
      editor:setPrompt(
      "(New Value): ",
      function(input)
         if item.validator then
            local ok, err = item.validator(input)
            if ok then
               accept(input)
            else
               nvim.api.errWriteln(
               ("Invalid input for item %q: %s"):format(
               item.name,
               assert(err, "no error message was returned from the validator")))


               vim.schedule(function()
                  editor:setLines(lines)
               end)
            end
         else
            accept(input)
         end
      end,
      close)

   end

   repeat
      render()
      local pressed = waitForKey(d, "<cr>", "<bs>")
      if pressed == "<cr>" then
         local row = d:getCursor()
         z.suspend(function(me)
            editDialog(self.items[row], me)
         end)
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
      local pressed = waitForKey(d, "<cr>", "<tab>", "<bs>", "<c-y>")
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