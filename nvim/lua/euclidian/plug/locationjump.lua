local nvim = require("euclidian.lib.nvim")

local locationjump = {}


function locationjump.parseLocation(loc)
   local file, line = loc:match("^(.*):(%d+)$")
   return file, tonumber(line)
end

function locationjump.jumpTo(filename, line)
   nvim.command("edit +%d %s", line, filename)
end

function locationjump.jumpToVisualSelection()
   local buf = nvim.Buffer()

   local a = buf:getMark("<")
   local b = buf:getMark(">")
   local lines = buf:getLines(a[1] - 1, b[1], true)
   if #lines ~= 1 then
      return
   end
   local text = lines[1]:sub(a[2] + 1, b[2] + 1)
   local file, line = locationjump.parseLocation(text)
   if file and line then
      nvim.command("edit +%d %s", line, file)
   else
      vim.api.nvim_err_writeln("Unable to parse file location from '" .. text .. "'")
   end
end

function locationjump.setVisualMap(key)
   nvim.setKeymap(
   "v",
   key,
   "<esc>:lua require('euclidian.plug.locationjump').jumpToVisualSelection()<cr>",
   { noremap = true, silent = true })

end

return locationjump