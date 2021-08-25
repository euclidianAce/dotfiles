
local dialog = require("euclidian.lib.dialog")
local z = require("euclidian.lib.async.zig")



local Accordion = {}







local new = {}

function new.accordion(items)
   return setmetatable({
      items = items,
      item_prefix = "* ",
      expanded_prefix = "- ",
      unexpanded_prefix = "+ ",
   }, { __index = Accordion })
end

local menu = {
   Accordion = Accordion,
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

local ns = vim.api.nvim_create_namespace("euclidian.plug.package-manager.menu")

function Accordion:run(opts)
   local d = dialog.new(opts)

   local State = {}



   local states = {}
   local lines
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
      lines[len] = ("  "):rep(indent) ..
      prefix ..
      item[1]
      if type(second) == "table" and s.enabled then
         for _, child in ipairs(second) do
            appendItem(child, indent + 1)
         end
      end
   end
   local function renderMenu()
      lines = {}
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
      local pressed = waitForKey(d, "<cr>", "<tab>", "<bs>")
      if pressed == "<cr>" or pressed == "<tab>" then
         local row = d:getCursor()
         for item, state in pairs(states) do
            local second = item[2]
            if state.line == row then
               if type(second) == "function" and pressed == "<cr>" then
                  d:close()
                  return second()
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