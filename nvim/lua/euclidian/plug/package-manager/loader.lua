
local packagespec = require("euclidian.plug.package-manager.packagespec")
local set = require("euclidian.plug.package-manager.set")
local report = require("euclidian.plug.package-manager.report")
local nvim = require("euclidian.lib.nvim")

local loader = {}

local Spec = packagespec.Spec

local function packadd(pkg)
   nvim.command("packadd " .. pkg)
end

local function getLoadOrder(loadedSet)
   local stages = setmetatable({}, {
      __index = function(self, key)
         rawset(self, key, {})
         return rawget(self, key)
      end,
   })

   for _, p in ipairs(loadedSet) do
      stages[1][p] = true
   end

   local idx = 1
   local maxLen = #loadedSet + 1
   repeat
      assert(idx <= maxLen, "circular dependency detected")
      local done = true

      for p in pairs(stages[idx]) do
         if p.dependents then
            done = false
            for _, dep in ipairs(p.dependents) do
               stages[idx][dep] = nil
               stages[idx + 1][dep] = true
            end
         end
      end
      idx = idx + 1
   until done

   local order = {}
   for _, stage in ipairs(stages) do
      for p in pairs(stage) do
         table.insert(order, p)
      end
   end

   return order
end

function loader.enableSet(setname)
   local pre, post = {}, {}
   local loaded, err = set.load(setname)
   if not loaded then
      report.err("Unable to load set %s: %s", setname, err)
      return
   end
   local ps = getLoadOrder(loaded)
   for _, pkg in ipairs(ps) do
      if pkg:isInstalled() then
         if pkg.kind == "git" then
            packadd(pkg:locationInTree())
         elseif pkg.kind == "local" then
            table.insert(pre, 1, pkg.path)
            table.insert(post, pkg.path .. "/after")
         end
      end
   end
   local rtp = nvim.api.listRuntimePaths()
   vim.list_extend(pre, rtp)
   vim.list_extend(pre, post);
   (vim).opt.runtimepath = pre
end

return loader