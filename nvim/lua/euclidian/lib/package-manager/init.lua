local actions = require("euclidian.lib.package-manager.actions")
local configure = require("euclidian.lib.package-manager.configure")
local loader = require("euclidian.lib.package-manager.loader")
local nvim = require("euclidian.lib.nvim")
local report = require("euclidian.lib.package-manager.report")

local packagemanager = {
   commands = {
      Add = actions.add,
      Install = actions.install,
      Update = actions.update,
      View = actions.listSets,
      Remove = actions.remove,
      Configure = actions.configure,
   },
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

function packagemanager._reload()
   local req = require

   report.msg("recompiling...")

   local err = {}
   local done = false
   require("euclidian.lib.command").spawn({
      command = { "cyan", "build" },
      cwd = os.getenv("DOTFILE_DIR") .. "/nvim",
      onStderrLine = function(line)
         table.insert(err, line)
      end,
      onExit = vim.schedule_wrap(function(code)
         if not code or code ~= 0 then
            report.err("cyan build exited with code %s, did not reload", tostring(code))
            local p = require("euclidian.lib.printmode").printfn("buffer")
            for _, ln in ipairs(err) do
               p((ln:gsub(string.char(27) .. "%[%d+m", "")))
            end
            return
         end

         report.msg("reloading...")
         for name in pairs(package.loaded) do
            if name:match("^euclidian%.lib%.package%-manager") then
               package.loaded[name] = nil
            end
         end
         req("euclidian.lib.package-manager")
         report.msg("reloaded!")
         done = true
      end),
   })
   repeat vim.wait(10)
   until done
end

packagemanager.commands._Reload = packagemanager._reload

nvim.newCommand({
   name = "PackageManager",
   nargs = 1,
   completelist = getCommandCompletion,
   body = function(cmd)
      if not packagemanager.commands[cmd] then
         report.err("Not a command: %s", tostring(cmd))
         return
      end
      packagemanager.commands[cmd]()
   end,
   bar = true,

   overwrite = true,
})

local cfg = assert(configure.load())

if cfg.maxConcurrentJobs then
   actions.maxConcurrentJobs = cfg.maxConcurrentJobs
end

for _, s in ipairs(cfg.enable) do
   loader.enableSet(s)
end

nvim.command("packloadall")