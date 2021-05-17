local packagemanager = {SetupOptions = {}, }










local nvim = require("euclidian.lib.nvim")
local loader = require("euclidian.lib.package-manager.loader")
local actions = require("euclidian.lib.package-manager.actions")

packagemanager.commands = {
   Add = actions.add,
   Install = actions.install,
   Update = actions.update,
   View = actions.listSets,
   Remove = actions.remove,
}

local function writeMsg(str, ...)
   print("PackageManager:", string.format(str, ...))
end

local function writeErr(str, ...)
   vim.api.nvim_err_write("PackageManager: ")
   vim.api.nvim_err_writeln(string.format(str, ...))
end

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

local function copyOpts(opts)
   return {
      enable = { unpack(opts.enable or {}) },
      maxConcurrentJobs = opts.maxConcurrentJobs,
   }
end

local loadedWith

function packagemanager._reload()
   local req = require

   writeMsg("recompiling...")
   local command = require("euclidian.lib.command")
   local err = {}
   command.spawn({
      command = { "cyan", "build" },
      cwd = os.getenv("DOTFILE_DIR") .. "/nvim",
      onStderrLine = function(line)
         table.insert(err, line)
      end,
      onExit = vim.schedule_wrap(function(code)
         if code ~= 0 then
            writeErr("cyan build exited with code %d, did not reload", code)
            require("euclidian.lib.printmode").printfn("buffer")(unpack(err))
            return
         end

         writeMsg("reloading...")
         for name in pairs(package.loaded) do
            if name:match("^euclidian%.lib%.package%-manager") then
               package.loaded[name] = nil
            end
         end;
         (req("euclidian.lib.package-manager"))(loadedWith)
         writeMsg("reloaded!")
      end),
   })
end

return setmetatable(packagemanager, {
   __call = function(_, opts)
      loadedWith = copyOpts(opts)

      nvim.newCommand({
         name = "PackageManager",
         nargs = 1,
         completelist = getCommandCompletion,
         body = function(cmd)
            if not packagemanager.commands[cmd] then
               writeErr("Not a command: %s", tostring(cmd))
               return
            end
            packagemanager.commands[cmd]()
         end,

         overwrite = true,
      })

      if not opts then return end
      if opts.maxConcurrentJobs then
         if opts.maxConcurrentJobs <= 0 then
            writeErr("maxConcurrentJobs should be a positive integer, got %s", tostring(opts.maxConcurrentJobs))
         else
            actions.maxConcurrentJobs = opts.maxConcurrentJobs
         end
      end

      if opts.enable then
         for _, s in ipairs(opts.enable) do
            loader.enableSet(s)
         end
      end
   end,
})