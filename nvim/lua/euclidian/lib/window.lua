
local a = vim.api

local window = {UI = {}, }








function window.init(winOpts, buf)
   if not buf then
      buf = a.nvim_create_buf(false, true)
   end
   local win = a.nvim_open_win(buf, true, winOpts)
   return win, buf
end


function window.ui()
   return (a.nvim_list_uis())[1]
end

function window.floating(col, row, wid, hei, buf)
   local ui = window.ui()

   if col < 0 then
      col = ui.width + col
   end
   if row < 0 then
      row = ui.height + row
   end

   local win
   win, buf = window.init({
      relative = "editor", style = "minimal", anchor = "NW",
      width = wid, height = hei,
      row = row, col = col,
   }, buf)
   return win, buf
end

local floor, max, min =
math.floor, math.max, math.min
local function getWinSize(wid, hei)
   local ui = window.ui()

   local minWid = floor(ui.width * .25)
   local minHei = floor(ui.height * .25)

   local maxWid = floor(ui.width * .90)
   local maxHei = floor(ui.height * .90)

   wid = min(max(minWid, wid), maxWid)
   hei = min(max(minHei, hei), maxHei)

   return math.floor((ui.width - wid) / 2), math.floor((ui.height - hei) / 2), wid, hei
end

function window.centeredFloat(wid, hei, buf)
   local col, row, actualWid, actualHei =
getWinSize(wid, hei)

   local win
   win, buf = window.init({
      relative = "editor", style = "minimal", anchor = "NW",
      width = actualWid, height = actualHei,
      row = row, col = col,
   }, buf)
   return win, buf
end

return window