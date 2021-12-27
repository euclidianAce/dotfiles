local nvim = require("euclidian.lib.nvim")
local dialog = require("euclidian.lib.dialog")
local z = require("euclidian.lib.azync")
local ns = vim.api.nvim_create_namespace("euclidian.lib.menu")



local Accordion = {Options = {}, }














local Modifiable = {Item = {}, }











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

local menu = {
   Accordion = Accordion,
   Modifiable = Modifiable,
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

   local State = {}



   local states = {}
   local lines = {}
   local function appendItem(item, indent)
      local len = #lines + 1
      local second = item[2]
      if not states[item] then
         states[item] = { enabled = false }
      end
      local s = states[item]
      s.line = len
      local prefix = ""
      if type(second) == "function" then
         prefix = self.item_prefix
      elseif second then
         prefix = s.enabled and
         self.expanded_prefix or
         self.unexpanded_prefix
      end
      lines[len] = ("  "):rep(indent) .. prefix .. item[1]
      if type(second) == "table" and s.enabled then
         for _, child in ipairs(second) do
            appendItem(child, indent + 1)
         end
      end
   end
   local function renderMenu()
      lines = {}
      for _, state in pairs(states) do
         state.line = -1
      end
      for _, item in ipairs(self.items) do
         appendItem(item, 0)
      end
      d:setLines(lines)
   end

   local buf = d:buf()
   local win = d:win()
   local winid = win.id
   win:setOption("winhl", win:getOption("winhl"))
   win:setOption("cursorline", true)
   buf:clearNamespace(ns, 0, -1)

   vim.api.nvim_set_decoration_provider(ns, {
      on_win = function(_, w)
         if winid ~= w then
            return false
         end
         return true
      end,
      on_line = function(_, _win, bufnr, row)
         if bufnr ~= buf.id then
            return false
         end
         local line = lines[row + 1]
         local leadingws = #line:match("^(%s*)")
         buf:setExtmark(ns, row, leadingws, {
            ephemeral = true,
            end_line = row,
            end_col = #line,
            hl_group = line:match("^%s*%*") and "Type" or
            line:match("^%s*[+-]") and "Special" or
            "Normal",
         })

         return true
      end,
   })

   while true do
      renderMenu()
      local pressed = waitForKey(d, "<cr>", "<tab>", "<bs>", "<2-LeftMouse>")

      if pressed == "<cr>" or pressed == "<tab>" or pressed == "<2-LeftMouse>" then
         local row = d:getCursor()
         for item, state in pairs(states) do
            local second = item[2]
            if state.line == row then
               if type(second) == "function" and (pressed == "<cr>" or pressed == "<2-LeftMouse>") then
                  if opts.persist then
                     second()
                  else
                     d:close()
                     return second()
                  end
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
               vim.api.nvim_err_writeln(
               ("Invalid input for item %q: %s"):format(item.name, tostring(err)))

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

   while true do
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
   end

   d:close()
end

return menu