
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