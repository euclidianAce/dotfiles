
local packagespec = require("euclidian.lib.package-manager.packagespec")
local set = require("euclidian.lib.package-manager.set")
local report = require("euclidian.lib.package-manager.report")

local loader = {}

local Spec = packagespec.Spec






local command = vim.api.nvim_command
local function packadd(pkg)
   command(([[packadd %s]]):format(pkg))
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

local function packaddSet(setname)
   local pre, post = {}, {}
   local loaded, err = set.load(setname)
   if not loaded then
      report.err("Unable to load set %s: %s", setname, err)
   end
   local ps = getLoadOrder(loaded)
   for _, pkg in ipairs(ps) do
      if pkg:isInstalled() then
         if pkg.kind == "git" then
            packadd(pkg.alias or pkg.repo:match("[^/]+$"))
         elseif pkg.kind == "local" then
            table.insert(pre, 1, pkg.path)
            table.insert(post, pkg.path .. "/after")
         end
      end
   end
   local rtp = vim.api.nvim_list_runtime_paths()
   vim.list_extend(pre, rtp)
   vim.list_extend(pre, post)
   command([[set rtp=]] .. table.concat(pre, ","))
end

function loader.enableSet(setname)

   packaddSet(setname)

end

return loader