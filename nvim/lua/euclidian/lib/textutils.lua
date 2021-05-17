local textutils = {}

function textutils.rightAlign(str, wid)
   assert(wid >= 0)
   return (" "):rep(wid - #str) .. str
end

function textutils.insertFormatted(list, fmt, ...)
   table.insert(list, string.format(fmt, ...))
end

return textutils