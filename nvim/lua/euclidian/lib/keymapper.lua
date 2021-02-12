
local MapArgs = {}








local util = require("euclidian.lib.util")
local a = vim.api

local function makeDefaultTable()
   return setmetatable({}, {
      __index = function(self, index)
         rawset(self, index, {})
         return self[index]
      end,
   })
end

local cmdf = util.nvim.cmdf

local keymapper = {
   _export = {
      mapping = makeDefaultTable(),
      bufMapping = setmetatable({}, {
         __index = function(self, key)
            cmdf("autocmd! BufUnload <buffer=%d> lua require('euclidian.lib.keymapper')._export.bufMapping[%d] = nil", key, key)
            rawset(self, key, makeDefaultTable())
            return rawget(self, key)
         end,
      }),
   },
}

local function keymapCallback(fn)
   local errored = false
   local err
   return function()
      if errored then
         a.nvim_err_writeln("Keymap previously errored: " .. err)
      else
         local ok, res = pcall(fn)
         if not ok then
            errored = true
            err = res
            a.nvim_err_writeln("Keymap errored: " .. err)
         end
      end
   end
end

local function sanitizeLhs(lhs)
   return (lhs:gsub("<.->", function(_s)
      local s = _s:sub(2, -2)
      if s == "leader" then
         return a.nvim_get_var("mapleader")
      elseif s:lower() == "esc" then
         return "_esc"
      end
      return _s
   end))
end

local function copyUserSettings(t)
   return t and {
      nowait = t.nowait,
      silent = t.silent,
      script = t.script,
      expr = t.expr,
      unique = t.unique,
      noremap = t.noremap,
   } or {}
end

local function map(mode, lhs, rhs, userSettings)
   if type(rhs) == "string" then
      a.nvim_set_keymap(mode, lhs, rhs, userSettings)
   elseif type(rhs) == "function" then
      local correct_lhs = sanitizeLhs(lhs)

      keymapper._export.mapping[mode][correct_lhs] = keymapCallback(rhs)
      local vimRhs = string.format("<cmd>lua require('euclidian.lib.keymapper')._export.mapping[%q][%q]()<CR>", mode, lhs)
      a.nvim_set_keymap(mode, lhs, vimRhs, userSettings)
   end
end

local function bufMap(buf, mode, lhs, rhs, userSettings)
   if type(rhs) == "string" then
      a.nvim_buf_set_keymap(buf, mode, lhs, rhs, userSettings)
   elseif type(rhs) == "function" then
      local correct_lhs = sanitizeLhs(lhs)

      keymapper._export.bufMapping[buf][mode][correct_lhs] = keymapCallback(rhs)
      local vimRhs = string.format("<cmd>lua require('euclidian.lib.keymapper')._export.bufMapping[%d][%q][%q]()<CR>", buf, mode, lhs)
      a.nvim_buf_set_keymap(buf, mode, lhs, vimRhs, userSettings)
   end
end

function keymapper.map(mode, lhs, rhs, userSettings)
   map(mode, lhs, rhs, copyUserSettings(userSettings))
end

function keymapper.bufMap(buf, mode, lhs, rhs, userSettings)
   bufMap(buf, mode, lhs, rhs, copyUserSettings(userSettings))
end

function keymapper.noremap(mode, lhs, rhs, userSettings)
   local s = copyUserSettings(userSettings)
   s.noremap = true
   map(mode, lhs, rhs, s)
end

function keymapper.unmap(mode, lhs)
   pcall(a.nvim_del_keymap, mode, sanitizeLhs(lhs))
end

return keymapper