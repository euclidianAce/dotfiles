
local MapArgs = {}








local util = require("euclidian.lib.util")
local a = vim.api

local keymapper = {
   _export = {
      mapping = setmetatable({}, {
         __index = function(self, index)
            rawset(self, index, {})
            return self[index]
         end,
      }),
   },
}

local function map(mode, lhs, rhs, user_settings)
   user_settings = user_settings or {}
   if type(rhs) == "string" then
      a.nvim_set_keymap(mode, lhs, rhs, user_settings)
   elseif type(rhs) == "function" then



      local correct_lhs = lhs:gsub("<leader>", a.nvim_get_var("mapleader"))
      keymapper._export.mapping[mode][correct_lhs] = util.partial(pcall, rhs)
      local vimRhs = string.format("<cmd>lua require('euclidian.lib.keymapper')._export.mapping[%q][%q]()<CR>", mode, lhs)
      a.nvim_set_keymap(
      mode,
      lhs,
      vimRhs,
      user_settings)

   end
end

local function copyUserSettings(t)
   return {
      nowait = t.nowait,
      silent = t.silent,
      script = t.script,
      expr = t.expr,
      unique = t.unique,
      noremap = t.noremap,
   }
end

function keymapper.map(mode, lhs, rhs, userSettings)
   map(mode, lhs, rhs, copyUserSettings(userSettings))
end

function keymapper.noremap(mode, lhs, rhs, userSettings)
   local s = copyUserSettings(userSettings)
   s.noremap = true
   map(mode, lhs, rhs, s)
end

function keymapper.unmap(mode, lhs)
   local correct_lhs = lhs:gsub("<leader>", a.nvim_get_var("mapleader"))
   pcall(a.nvim_del_keymap, mode, correct_lhs)
end

return keymapper