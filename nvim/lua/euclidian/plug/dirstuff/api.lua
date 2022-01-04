local nvim = require("euclidian.lib.nvim")
local uv = vim.loop

local groupFromId
local userFromId

do
   local user_cache = nil
   local group_cache = nil

   groupFromId = function(id)
      if not group_cache then
         group_cache = {}
         for ln in assert(io.lines("/etc/group")) do
            local name, gid = ln:match("([%w-_]+):[^:]*:(%d+)")
            group_cache[tonumber(gid)] = name
         end
      end
      return group_cache[id]
   end

   userFromId = function(id)
      if not user_cache then
         user_cache = {}
         for ln in assert(io.lines("/etc/passwd")) do
            local name, uid = ln:match("([%w-_]+):[^:]*:(%d+)")
            user_cache[tonumber(uid)] = name
         end
      end
      return user_cache[id]
   end
end

local filetypes = {
   file = "-",
   directory = "d",
   link = "l",
}

local suffixes = { "", "K", "M", "G", "T", "P", "E", "Z", "Y" }
local function humanReadableSize(sz)
   local l = math.floor(math.log(sz) / math.log(10))
   for i, s in ipairs(suffixes) do
      if l < i * 3 then
         if i == 1 then
            return ("% 4d"):format(sz)
         end
         return ("%.1f" .. s):format(sz / (10 ^ ((i - 1) * 3)))
      end
   end
   return ("%.1e"):format(sz)
end

local Permissions = {}





local Stat = {}











local dir = {
   Stat = Stat,
   Permissions = Permissions,
}

local function convertPermissions(n)
   return {
      read = (bit32.band(n, 4)) > 0,
      write = (bit32.band(n, 2)) > 0,
      execute = (bit32.band(n, 1)) > 0,
   }
end

local function convertStat(stat)
   return {
      type = stat.type,
      size = stat.size,
      groupPermissions = convertPermissions(bit32.rshift(stat.mode, 6)),
      ownerPermissions = convertPermissions(bit32.rshift(stat.mode, 3)),
      otherPermissions = convertPermissions(stat.mode),
      owner = userFromId(stat.uid),
      group = groupFromId(stat.gid),
      nlink = stat.nlink,
      modificationTime = stat.mtime.sec,
   }
end

function dir.stat(filename)
   local stat, err = uv.fs_stat(filename)
   if not stat then return nil, err end
   return convertStat(stat)
end

function dir.lstat(filename)
   local stat, err = uv.fs_lstat(filename)
   if not stat then return nil, err end
   return convertStat(stat)
end

function dir.permsToString(p)
   return ("%s%s%s"):format(
   p.read and "r" or "-",
   p.write and "w" or "-",
   p.execute and "x" or "-")

end

function dir.statToString(stat)
   return ("%s%s%s%s %2d %s %s %s %s"):format(
   filetypes[stat.type] or "?",
   dir.permsToString(stat.ownerPermissions),
   dir.permsToString(stat.groupPermissions),
   dir.permsToString(stat.otherPermissions),
   stat.nlink,
   stat.owner,
   stat.group,
   humanReadableSize(stat.size),
   os.date("%b %2d %R", stat.modificationTime))

end

function dir.statString(filename)
   local stat, err = uv.fs_stat(filename)
   if not stat then return nil, err end
   return dir.statToString(convertStat(stat))
end

function dir.lstatString(filename)
   local stat, err = uv.fs_lstat(filename)
   if not stat then return nil, err end
   return dir.statToString(convertStat(stat))
end



function dir.ls(dirname, buf)
   assert(buf)
   assert(buf:isValid())
   local scanner, err = uv.fs_scandir(dirname)
   if not scanner then
      buf:setLines(0, -1, false, {
         "unable to scandir: " .. tostring(dirname),
         err,
      })
      return
   end
   local dirs = {}
   local files = {}
   for f in uv.fs_scandir_next, scanner do
      local stat = assert(dir.lstat(dirname .. "/" .. f))
      local t = stat.type
      if t == "directory" then
         table.insert(dirs, { f, stat })
      else

         table.insert(files, { f, stat })
      end
   end

   local function cmp(a, b)
      return a[1] < b[1]
   end

   table.sort(dirs, cmp)
   table.sort(files, cmp)

   local stats = {}
   local lines = {}
   local function ins(s)
      table.insert(stats, s[2])

      table.insert(
      lines,
      ("%s %s%s"):format(
      dir.statToString(s[2]),
      s[1],
      s[2].type == "directory" and "/" or ""))


   end
   for _, v in ipairs(dirs) do ins(v) end
   for _, v in ipairs(files) do ins(v) end

   buf:setLines(0, -1, false, lines)

















end

return dir