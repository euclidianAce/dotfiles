local nvim = require("euclidian.lib.nvim")

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

   add = nil,
   enable = nil,

   start = nil,
   finish = nil,
}

local Saved = {}




local old

opnum.start = vim.schedule_wrap(function()
   local win = nvim.Window()
   old = {
      win = win,
      number = win:getOption("number"),
      relativenumber = win:getOption("relativenumber"),
   }

   win:setOption("relativenumber", true)
end)

opnum.finish = vim.schedule_wrap(function()
   if old and old.win:isValid() then
      old.win:setOption("number", old.number)
      old.win:setOption("relativenumber", old.relativenumber)
   end
   old = nil
end)

function opnum.enable(...)
   for i = 1, select("#", ...) do
      table.insert(opnum.leaders, (select(i, ...)))
   end

   for _, leader in ipairs(opnum.leaders) do
      vim.keymap.set("n", leader, "<cmd>call v:lua.require'euclidian.plug.opnum.api'.start()<cr>" .. leader, { silent = true })
   end
   vim.keymap.set("o", "<esc>", "<cmd>call v:lua.require'euclidian.plug.opnum.api'.finish()<cr>", { silent = true })
   vim.keymap.set("o", "<c-c>", "<cmd>call v:lua.require'euclidian.plug.opnum.api'.finish()<cr>", { silent = true })

   local group = "ResetLineNumberAfterOperator"
   nvim.api.createAugroup(group, { clear = true })
   nvim.api.createAutocmd(
   { "CursorMoved", "CursorMovedI", "BufLeave", "TextYankPost" },
   {
      pattern = "*",
      callback = opnum.finish,
      group = group,
   })

end

return opnum