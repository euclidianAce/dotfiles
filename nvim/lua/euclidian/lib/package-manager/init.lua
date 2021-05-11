
local packagemanager = {SetupOptions = {}, }










local nvim = require("euclidian.lib.nvim")
local loader = require("euclidian.lib.package-manager.loader")
local actions = require("euclidian.lib.package-manager.actions")

packagemanager.commands = {
   Add = actions.add,
   Install = actions.install,
   Update = actions.update,
   View = actions.listSets,
}

local function getCommandCompletion(arglead)
   arglead = arglead or ""
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


      nvim.newCommand({
         name = "PackageManager",
         nargs = 1,
         completelist = getCommandCompletion,
         body = function(cmd)
            packagemanager.commands[cmd]()
         end,

         overwrite = true,
      })

      if not opts then return end
      if opts.maxConcurrentJobs then
         actions.maxConcurrentJobs = opts.maxConcurrentJobs
      end

      for _, s in ipairs(opts.enable or {}) do
         loader.enableSet(s)
      end
   end,
})