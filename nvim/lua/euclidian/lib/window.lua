
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
   return a.nvim_list_uis()[1]
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

return window
