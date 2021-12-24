local nvim = require("euclidian.lib.nvim")

local locationjump = {}

local pattern = "([^%s:]+):(%d+)"

function locationjump.jump(filename, line)
   if line then
      nvim.command("edit +%d %s", line, filename)
   elseif filename then
      nvim.command("edit %s", filename)
   end
end

function locationjump.selectLocation(locations)
   if #locations > 1 then
      vim.ui.select(locations, {
         prompt = "Multiple locations found:",
         format_item = function(item)
            if item[2] then
               return ("%s @ line %d"):format(item[1], item[2])
            end
            return ("%s"):format(item[1])
         end,
      }, function(item)
         if item then
            locationjump.jump(item[1], item[2])
         end
      end)
   else
      locationjump.jump(locations[1][1], locations[1][2])
   end
end

function locationjump.setPattern(p)
   pattern = p
end

function locationjump.parseAllLocations(str)
   local results = {}
   for a, b in str:gmatch(pattern) do
      local n = tonumber(b)
      table.insert(results, { a, n })
   end
   if #results == 0 then
      vim.api.nvim_err_writeln("locationjump: Unable to parse file location from '" .. str .. "'")
   end
   return results
end


function locationjump.parseLocation(loc)
   assert(loc)
   local file, line = loc:match("^" .. pattern .. "$")
   return file, tonumber(line)
end

function locationjump.parseAndJump(text)
   local results = locationjump.parseAllLocations(text)
   locationjump.selectLocation(results)
end

function locationjump.jumpToVisualSelection()
   local buf = nvim.Buffer()

   local a = buf:getMark("<")
   local b = buf:getMark(">")
   local lines = buf:getLines(a[1] - 1, b[1], true)
   local text = table.concat(lines, "\n")

   local results = locationjump.parseAllLocations(text)
   locationjump.selectLocation(results)
end

function locationjump.jumpExpand(expandArg)
   locationjump.parseAndJump(vim.fn.expand(expandArg))
end

return locationjump