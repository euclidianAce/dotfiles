local nvim = require("euclidian.lib.nvim")

local OpNum = {}








local opnum = {
   leaders = {

      "c",
      "d",
      "y",
      "g~",
      "gu",
      "gU",
      "!",
      "=",
      "gq",
      "gw",
      "g?",
      ">",
      "<",
      "zf",
      "g@",
   },
}

local Saved = {}




local old

opnum._start = vim.schedule_wrap(function()
   local win = nvim.Window()
   old = {
      win = win,
      number = win:getOption("number"),
      relativenumber = win:getOption("relativenumber"),
   }

   win:setOption("relativenumber", true)
end)

opnum._finish = vim.schedule_wrap(function()
   if old and old.win:isValid() then
      old.win:setOption("number", old.number)
      old.win:setOption("relativenumber", old.relativenumber)
   end
end)

function opnum.add(leader)
   table.insert(opnum.leaders, leader)
   return opnum
end

function opnum.enable()
   for _, leader in ipairs(opnum.leaders) do
      nvim.setKeymap("n", leader, "<cmd>call v:lua.require'euclidian.plug.opnum'._start()<cr>" .. leader, { noremap = true, silent = true })
   end
   nvim.setKeymap("o", "<esc>", "<cmd>call v:lua.require'euclidian.plug.opnum'._finish()<cr>", { noremap = true, silent = true })
   nvim.setKeymap("o", "<c-c>", "<cmd>call v:lua.require'euclidian.plug.opnum'._finish()<cr>", { noremap = true, silent = true })

   nvim.augroup("ResetLineNumberAfterOperator", {
      { { "CursorMoved", "CursorMovedI", "BufLeave", "TextYankPost" }, "*", opnum._finish },
   }, true)
end

return opnum