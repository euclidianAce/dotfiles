local nvim = require("euclidian.lib.nvim")

__euclidian.manfolder = function()
   local lnum = assert(vim.v.lnum)

   if lnum == 1 then
      return 0
   end
   local line = nvim.Buffer():getLines(lnum - 1, lnum, false)[1]


   if not line or
      #line == 0 or
      line:match("^%s") then

      return "="
   elseif line:match("^[A-Z][A-Z%s]+$") then
      return ">1"
   else
      return 0
   end
end

do
   local group = "ManFolder"
   nvim.api.createAugroup(group, { clear = true })
   nvim.api.createAutocmd("FileType", {
      pattern = "man",
      command = "setlocal foldexpr=v:lua.__euclidian.manfolder() | setlocal foldmethod=expr",
      group = group,
   })
end

return __euclidian.manfolder