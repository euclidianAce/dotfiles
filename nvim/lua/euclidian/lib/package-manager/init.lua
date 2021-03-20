local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs
local packagemanager = {SetupOptions = {}, }









local nvim = require("euclidian.lib.nvim")
local loader = require("euclidian.lib.package-manager.loader")
local actions = require("euclidian.lib.package-manager.actions")

packagemanager.commands = {
   View = actions.listSets,
   Install = actions.install,
   Update = actions.update,
   Add = actions.add,
}

return setmetatable(packagemanager, {
   __call = function(_, opts)

      nvim.command([[ command -nargs=1 PackageManager lua require'euclidian.lib.package-manager'.commands['<args>']() ]])

      if not opts then return end
      for _, s in ipairs(opts.enable or {}) do
         loader.enableSet(s)
      end
   end,
})