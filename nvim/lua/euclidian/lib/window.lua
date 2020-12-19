
local a = vim.api

local window = {}




local NvimUI = {}




local function getUI()
   return a.nvim_list_uis()[1]
end

local function initWin(winOpts)
   local buf = a.nvim_create_buf(false, true)
   local win = a.nvim_open_win(buf, true, winOpts)
   return win, buf
end

local function floating(row, col, wid, hei)
   local win, buf = initWin({
      relative = "editor", style = "minimal", anchor = "NW",
      width = wid, height = hei,
      row = row, col = col,
   })
   return win, buf
end

return {
   t = window,
   new = {
      floating = floating,
   },
}
