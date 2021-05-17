local textutils = {}

function textutils.rightAlign(str, wid)
   assert(wid >= 0)
   return (" "):rep(wid - #str) .. str
end

function textutils.insertFormatted(list, fmt, ...)
   table.insert(list, string.format(fmt, ...))
end

function textutils.limit(str, len, showTail)
   return showTail and
   string.sub(str, -len) or
   string.sub(str, 1, len)
end

return textutils