local nvim = require("euclidian.lib.nvim")
local terminal = require("euclidian.lib.terminal")
local dialog = require("euclidian.lib.dialog")

local Terminal = terminal.Terminal
local Dialog = dialog.Dialog

local FloatTerm = {Mappings = {}, }


















local function setMap(map, func) vim.keymap.set(map[1], map[2], func, map[3]) end
local function delMap(map) vim.keymap.del(map[1], map[2], map[3]) end

local floatterm = {
   FloatTerm = FloatTerm,
}

local function copyKeymaps(map)
   return {
      show = map.show and { unpack(map.show, 1, 3) },
      hide = map.hide and { unpack(map.hide, 1, 3) },
      toggle = map.toggle and { unpack(map.toggle, 1, 3) },
   }
end

function floatterm.new(
   dialogOpts,
   cmd,
   termOpts,
   mappings)

   local buf = nvim.createBuf(false, true)

   dialogOpts.hidden = true
   dialogOpts.interactive = true
   local t = setmetatable({
      dialog = dialog.new(dialogOpts, buf),
      terminal = terminal.create(cmd, termOpts, buf),
      mappings = mappings and copyKeymaps(mappings),
   }, { __index = FloatTerm })
   if t.mappings and t.mappings.toggle then
      setMap(
      t.mappings.toggle,
      function() t:toggle() end)

   end
   return t
end

function FloatTerm:show()
   self.terminal:ensureOpen()
   self.dialog:show()
   if self.mappings then
      if self.mappings.hide then
         setMap(
         self.mappings.hide,
         function() self:hide() end)

      end
      if self.mappings.show then
         delMap(self.mappings.show)
      end
   end
end

function FloatTerm:hide()
   self.dialog:hide()
   if self.mappings then
      if self.mappings.show then
         setMap(
         self.mappings.show,
         function() self:show() end)

      end
      if self.mappings.hide then
         delMap(self.mappings.hide)
      end
   end
end

function FloatTerm:toggle()
   if self.dialog:win():isValid() then
      self:hide()
   else
      self:show()
   end
end

function FloatTerm:close()
   self.dialog:close()
   self.terminal:close()
end

return floatterm