local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local io = _tl_compat and _tl_compat.io or io; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table
local tree = require("euclidian.lib.package-manager.tree")
local packagespec = require("euclidian.lib.package-manager.packagespec")
local Spec = packagespec.Spec
local uv = vim.loop

local set = {}
local setPath = tree.set

local ti, sf = table.insert, string.format
local function tiFmt(t, s, ...)
   ti(t, sf(s, ...))
end

local function generateDef(out, p)
   assert(p.id, "Attempt to generate package def without id")
   local leadingSpaces = (" "):rep(#("Package { "))

   local function ins(s, ...)
      tiFmt(out, leadingSpaces .. s, ...)
      tiFmt(out, ",\n")
   end

   tiFmt(out, "Package { kind = %q,\n", p.kind)
   ins("id = %d", p.id)

   if p.alias then
      ins("alias = %q", p.alias)
   end
   if p.kind == "git" then
      ins("repo = %q", p.repo)
      if p.branch then
         ins("branch = %q", p.branch)
      end
   elseif p.kind == "local" then
      ins("path = %q", p.path)
   end

   if p.dependents then
      local d = {}
      for _, dep in ipairs(p.dependents) do
         if type(dep) == "table" and dep.id then
            table.insert(d, tostring(dep.id))
         end
      end

      if #d > 0 then
         ins("dependents = { %s }", table.concat(d, ", "))
      end
   end

   if p.post then
      ins("post = %q", p.post)
   end

   table.remove(out)
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

   table.insert(out, "\n-- vim: ft=teal")

   return table.concat(out)
end

function set.deserialize(str)
   local packages = {}

   local largestId = -1
   local function Package(p)
      assert(p.id, "Package has no id!")
      packages[p.id] = packagespec.new(p)
      if p.id > largestId then
         largestId = p.id
      end
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


   for i = largestId, 1, -1 do
      if packages[i] == nil then
         table.remove(packages, i)
      end
   end

   return packages
end



local function loadSet(name)
   local fh = assert(io.open(setPath .. "/" .. name, "r"))
   local content = fh:read("*a")
   fh:close()
   return set.deserialize(content)
end

local loadedSets = {}
function set.load(name)
   if not loadedSets[name] then
      loadedSets[name] = loadSet(name)
   end
   return loadedSets[name]
end

function set.save(name, s)
   assert(name, "Can't save a set without a name"); assert(s, "No set to save")
   local fh = assert(io.open(setPath .. "/" .. name, "w"))
   fh:write(set.serialize(s), "\n")
   fh:close()
   loadedSets[name] = nil
end

function set.list()
   local list = {}
   local dir = uv.fs_scandir(setPath)
   for name in uv.fs_scandir_next, dir do
      table.insert(list, name)
   end
   return list
end

return set