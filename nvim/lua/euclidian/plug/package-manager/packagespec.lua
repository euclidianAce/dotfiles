local fs = require("euclidian.lib.fs")
local tree = require("euclidian.plug.package-manager.tree")

local Kind = {}




local Spec = {}



















local packagespec = {
   Spec = Spec,
   Kind = Kind,
   kinds = {
      ["git"] = true,
      ["local"] = true,
   },
}

local spec_mt = {
   __index = Spec,
   __lt = function(a, b)
      return a:title() < b:title()
   end,
}
function packagespec.new(p)
   return setmetatable(p, spec_mt)
end

function Spec:locationInTree()
   if self.kind == "git" then
      if self.alias then
         return self.alias
      else
         local loc = self.remote:match("[^/]+$")
         if loc:match("%.git$") then
            return loc:sub(1, -5)
         end
         return loc
      end
   end
end

function Spec:location()
   if self.kind == "git" then
      return tree.neovim .. "/" .. self:locationInTree()
   elseif self.kind == "local" then
      return self.path
   end
end

function Spec:title()
   if self.kind == "git" then
      if self.alias then
         return self.alias .. " (" .. self:locationInTree() .. ")"
      end
      return self:locationInTree()
   elseif self.kind == "local" then
      return self.path
   end
end

function Spec:installCmd()
   if self.kind == "git" then
      return { "git", "clone", "--progress", "--depth=1", self.remote, self:location() }
   end
end

function Spec:updateCmd()
   if self.kind == "git" then
      return { "git", "-C", self:location(), "pull" }
   end
end

function Spec:isInstalled()
   if self.kind == "git" then
      return fs.exists(self:location())
   else
      return true
   end
end

return packagespec