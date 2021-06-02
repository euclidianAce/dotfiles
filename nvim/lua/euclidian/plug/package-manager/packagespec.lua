
local tree = require("euclidian.plug.package-manager.tree")
local uv = vim.loop

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
         return self.repo:match("[^/]+$")
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
      return self.repo .. (self.alias and " (" .. self.alias .. ")" or "")
   elseif self.kind == "local" then
      return self.path
   end
end

function Spec:installCmd()
   if self.kind == "git" then
      return { "git", "clone", "--progress", "https://github.com/" .. self.repo, self:location() }
   end
end

function Spec:updateCmd()
   if self.kind == "git" then
      return { "git", "-C", self:location(), "pull" }
   end
end

local function fileExists(fname)
   return uv.fs_stat(fname) ~= nil
end

function Spec:isInstalled()
   if self.kind == "git" then
      return fileExists(self:location())
   else
      return true
   end
end

return packagespec