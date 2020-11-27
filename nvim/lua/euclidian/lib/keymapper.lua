
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
   local user_settings = user_settings or {}
   if type(rhs) == "string" then
      a.nvim_set_keymap(mode, lhs, rhs, user_settings)
   elseif type(rhs) == "function" then

      local correct_lhs = lhs:gsub("<leader>", a.nvim_get_var("mapleader"))
      keymapper._export.mapping[mode][correct_lhs] = util.partial(pcall, rhs)
      a.nvim_set_keymap(
mode,
lhs,
string.format(":lua require('euclidian.lib.keymapper')._export.mapping[%q][%q]()<CR>", mode, lhs),
user_settings)

   end
end

function keymapper.map(mode, lhs, rhs, userSettings)
   map(mode, lhs, rhs, userSettings or {})
end

function keymapper.noremap(mode, lhs, rhs, userSettings)
   map(mode, lhs, rhs, vim.tbl_extend("keep", { noremap = true }, userSettings or {}))
end

function keymapper.unmap(mode, lhs)
   local correct_lhs = lhs:gsub("<leader>", a.nvim_get_var("mapleader"))
   pcall(a.nvim_del_keymap, mode, correct_lhs)
end

return keymapper
