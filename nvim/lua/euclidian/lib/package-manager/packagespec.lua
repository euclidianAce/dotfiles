

local tree = require("euclidian.lib.package-manager.tree")

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

function packagespec.new(p)
   return setmetatable(p, { __index = Spec })
end

function Spec:location()
   if self.kind == "git" then
      if self.alias then
         return tree.neovim .. "/" .. self.alias
      else
         return tree.neovim .. "/" .. self.repo:match("[^/]+$")
      end
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

math.randomseed(os.time())
function Spec:installCmd()
   if self.kind == "git" then

      local cmd = {}
      for i = 1, math.random(3, 10) do
         if math.random() < .5 then
            table.insert(cmd, "sleep " .. tostring(math.random(.01, .5)) .. ";")
         else
            table.insert(cmd, "echo step " .. tostring(i) .. ";")
         end
      end
      table.insert(cmd, "echo git clone https://github.com/" .. self.repo .. " " .. self:location())
      return { "sh", "-c", table.concat(cmd, " ") }
   end
end

local glob = vim.fn.glob
function Spec:isInstalled()
   if self.kind == "git" then
      local loc = self:location()
      if glob(loc) then
         return true
      end
   else
      return true
   end
   return false
end

return packagespec
