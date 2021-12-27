local z = require("euclidian.lib.azync")
local uv = vim.loop

local fs = {}

function fs.mkdirp(path)
   local components = vim.split(path, "/")
   for i = 1, #components do
      uv.fs_mkdir(table.concat(components, "/", 1, i), tonumber("755", 8))
   end
end

function fs.exists(fname)
   return uv.fs_stat(fname) ~= nil
end

function fs.ls(dirname, show_hidden)
   local scanner = uv.fs_scandir(dirname)
   return function()
      if not scanner then return end
      local name
      repeat
         name = uv.fs_scandir_next(scanner)
         if show_hidden then
            return name
         end
      until not name or name:sub(1, 1) ~= "."
      return name
   end
end

local function wrap(fn)
   return function(...)
      local n = select("#", ...)
      local args = { ... }
      local frame = z.currentFrame()
      local ret
      local err;
      (args)[n + 1] = function(e, r)
         err = e
         ret = r
         z.resume(frame)
      end
      z.suspend(function()
         fn(unpack(args, 1, n + 1))
      end)
      return ret, err
   end
end

local open = wrap(uv.fs_open)
local fstat = wrap(uv.fs_fstat)
local read = wrap(uv.fs_read)
local write = wrap(uv.fs_write)
local close = wrap(uv.fs_close)

function fs.read(path)
   local ok, res = pcall(function()
      local fd = assert(open(path, "r", 438))
      local stat = assert(fstat(fd))
      local data = assert(read(fd, stat.size, 0))
      assert(close(fd))
      return data
   end)
   if not ok then
      return nil, res
   end

   return res
end

function fs.write(path, data)
   local ok, res = pcall(function()
      local fd = assert(open(path, "w", 438))
      local r = assert(write(fd, data, 0))
      assert(close(fd))
      return r
   end)
   if not ok then
      return nil, res
   end

   return res
end


return fs