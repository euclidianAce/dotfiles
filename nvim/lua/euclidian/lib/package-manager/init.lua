
local packagemanager = {SetupOptions = {}, }









local loader = require("euclidian.lib.package-manager.loader")
local actions = require("euclidian.lib.package-manager.actions")

packagemanager.commands = {
   Add = actions.add,
   Install = actions.install,
   Update = actions.update,
   View = actions.listSets,
}

function packagemanager.getCommandCompletion(arglead)
   local keys = {}
   local len = #arglead
   for k in pairs(packagemanager.commands) do
      if k:sub(1, len):lower() == arglead:lower() then
         table.insert(keys, k)
      end
   end
   table.sort(keys)
   return keys
end

return setmetatable(packagemanager, {
   __call = function(_, opts)

      (_G)["__package_manager_cmpl"] = packagemanager.getCommandCompletion


      vim.cmd([[ command -complete=customlist,v:lua.__package_manager_cmpl -nargs=1 PackageManager lua require'euclidian.lib.package-manager'.commands['<args>']() ]])

      if not opts then return end
      for _, s in ipairs(opts.enable or {}) do
         loader.enableSet(s)
      end
   end,
})