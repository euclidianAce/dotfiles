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

return fs