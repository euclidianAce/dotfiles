local ims = require("euclidian.lib.imserialize")
local tree = require("euclidian.plug.package-manager.tree")

local Options = {}




local function fillWithDefaults(opts)
   opts.enable = opts.enable or {}
   opts.maxConcurrentJobs = opts.maxConcurrentJobs or 2
end

local configure = {
   Options = Options,
}

local filename = ".Config"

function configure.load()
   local fh, err = io.open(tree.set .. "/" .. filename, "r")
   if not fh then
      if err:match("No such file or directory") then
         local wfh = assert(io.open(tree.set .. "/" .. filename, "w"))
         wfh:write("return {}")
         wfh:close()
         local o = {}
         fillWithDefaults(o)
         return o
      end
      return nil, err
   end
   local content = fh:read("*a")
   fh:close()

   local chunk, loaderr = loadstring(content)
   if not chunk then
      return nil, loaderr
   end
   local ok, res = pcall(chunk)
   if not ok then
      return nil, res
   end
   if not (type(res) == "table") then
      return nil, "Expected a table"
   end
   fillWithDefaults(res)
   return res
end

function configure.save(opts)
   local fh, err = io.open(tree.set .. "/" .. filename, "w")
   if not fh then
      return false, err
   end

   fh:write("return ")

   ims.begin(fh, { newlines = true, indent = "   " })
   ims.beginTable()
   ims.key("enable")
   ims.beginTable()
   for _, s in ipairs(opts.enable) do
      ims.string(s)
   end
   ims.endTable()
   ims.key("maxConcurrentJobs")
   ims.integer(opts.maxConcurrentJobs or 2)
   ims.endTable()

   ims.finish()
   fh:close()
   return true
end

return configure