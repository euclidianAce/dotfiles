
local packagespec = require("euclidian.lib.package-manager.packagespec")
local Spec = packagespec.Spec

local set = {}

local ti, sf = table.insert, string.format
local function tiFmt(t, s, ...)
   ti(t, sf(s, ...))
end

local function generateDef(out, p)
   assert(p.id, "Attempt to generate package def without id")
   local leadingSpaces = (" "):rep(#("Package { "))

   local function ins(s, ...)
      tiFmt(out, leadingSpaces .. s, ...)
   end
   local function commaNewline()
      tiFmt(out, ",\n")
   end

   tiFmt(out, "Package { kind = %q", p.kind); commaNewline()
   ins("id = %d", p.id); commaNewline()

   if p.alias then
      ins("alias = %q", p.alias); commaNewline()
   end
   if p.kind == "git" then
      ins("repo = %q", p.repo)
      if p.branch then
         commaNewline()
         ins("branch = %q", p.branch)
      end
   elseif p.kind == "local" then
      ins("path = %q", p.path)
   end
   commaNewline()

   if p.dependents then
      local d = {}
      for _, dep in ipairs(p.dependents) do
         if type(dep) == "table" then
            table.insert(d, tostring(dep.id))
         end
      end

      if #d > 0 then
         ins("dependents = { %s }", table.concat(d, ", "))
      else
         table.remove(out)
      end
   else
      table.remove(out)
   end

   tiFmt(out, " }\n")
end

function set.serialize(ps)
   local out = {}
   local pkgs = {}

   local lastId = 0
   local function nextId()
      lastId = lastId + 1
      return lastId
   end

   local function gen(p)
      if not p.id then
         p.id = nextId()
         generateDef(out, p)
         pkgs[p.id] = p
      end
   end

   for _, p in ipairs(ps) do
      for _, dep in ipairs(p.dependents or {}) do
         gen(dep)
      end
      gen(p)
   end

   return table.concat(out)
end

function set.deserialize(str)
   local packages = {}

   local function Package(p)
      assert(p.id, "Package has no id!")
      packages[p.id] = packagespec.new(p)
   end

   local chunk = assert(loadstring(str))
   setfenv(chunk, { Package = Package })

   chunk()

   for _, pkg in pairs(packages) do
      pkg.id = nil
      if pkg.dependents then
         for i, depId in ipairs(pkg.dependents) do
            pkg.dependents[i] = packages[depId]
         end
      end
   end

   return packages
end

local loadedSets = {}
local setPath = vim.fn.stdpath("config") .. "/sets"
local function loadSet(name)

   local fh = assert(io.open(setPath .. "/" .. name, "r"))
   local content = fh:read("*a")
   fh:close()
   return set.deserialize(content)
end

function set.load(name)
   if not loadedSets[name] then
      loadedSets[name] = loadSet(name)
   end
   return loadedSets[name]
end

function set.save(name, s)
   assert(name); assert(s)
   local fh = assert(io.open(setPath .. "/" .. name, "w"))
   fh:write(set.serialize(s), "\n")
   fh:close()
end

local map = vim.tbl_map
local glob = vim.fn.glob

function set.list()
   return map(function(s)
      return s:sub(#setPath + 2, -1)
   end, glob(setPath .. "/*", true, true))
end

return set
