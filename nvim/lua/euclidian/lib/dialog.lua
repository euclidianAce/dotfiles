local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math
local nvim = require("euclidian.lib.nvim")

local Dialog = {Opts = {}, }











local dialog = {
   Dialog = Dialog,
}

function dialog.new(col, row, wid, hei)
   local buf = nvim.createBuf(false, true)
   buf:setOption("buftype", "nofile")
   buf:setOption("modifiable", false)

   local win = nvim.openWin(buf, true, {
      relative = "editor",
      row = row, col = col,
      width = wid, height = hei,
   })
   win:setOption("winblend", 5)

   local ui = nvim.ui()

   if col < 0 then
      col = ui.width + col
   end
   if row < 0 then
      row = ui.height + row
   end

   win:setConfig({
      relative = "editor", style = "minimal", anchor = "NW",
      width = wid, height = hei,
      row = row, col = col,
   })

   return setmetatable({ buf = buf, win = win }, { __index = Dialog })
end

local floor, max, min =
math.floor, math.max, math.min

local function clamp(n, lower, upper)
   return min(max(lower, n), upper)
end

function dialog.centeredSize(wid, hei)
   local ui = nvim.ui()

   local actualWid = clamp(
   wid,
   floor(ui.width * .25),
   floor(ui.width * .90))

   local actualHei = clamp(
   hei,
   floor(ui.height * .25),
   floor(ui.height * .90))


   return
math.floor((ui.width - actualWid) / 2),
   math.floor((ui.height - actualHei) / 2),
   actualWid,
   actualHei
end

function dialog.centered(wid, hei)
   return dialog.new(dialog.centeredSize(wid, hei))
end

function Dialog:isModifiable()
   return self.buf:getOption("modifiable")
end
function Dialog:setModifiable(to)
   self.buf:setOption("modifiable", to)
end
function Dialog:modify(fn)
   local orig = self:isModifiable()
   self:setModifiable(true)
   fn(self)
   self:setModifiable(orig)
   return self
end
function Dialog:setLines(txt)
   return self:modify(function()
      self.buf:setLines(0, -1, false, txt)
   end)
end
function Dialog:setText(edits)

   return self:modify(function()
      for _, edit in ipairs(edits) do
         self.buf:setText(edit[2], edit[3], edit[4], edit[5], { edit[1] })
      end
   end)
end
function Dialog:setCursor(row, col)
   self.win:setCursor({ row, col })
   return self
end
function Dialog:getCursor()
   local pos = self.win:getCursor()
   return pos[1], pos[2]
end
function Dialog:getLine(n)
   return self.buf:getLines(n - 1, n, false)[1]
end
function Dialog:getLines(min, max)
   return self.buf:getLines(min or 0, max or -1, false)
end
function Dialog:setWin(o)
   self.win:setConfig({
      relative = "editor",
      row = assert(o.row, "no row"), col = assert(o.col, "no col"),
      width = assert(o.wid, "no wid"), height = assert(o.hei, "no hei"),
   })
   return self
end
function Dialog:center(width, height)
   local col, row, wid, hei = dialog.centeredSize(width, height)
   self:setWin({ col = col, row = row, wid = wid, hei = hei })
   return self
end
function Dialog:addKeymap(mode, lhs, rhs, opts)
   self.buf:setKeymap(mode, lhs, rhs, opts)
   return self
end
function Dialog:delKeymap(mode, lhs)
   self.buf:delKeymap(mode, lhs)
   return self
end
function Dialog:setPrompt(prompt, cb, int)
   self.buf:setOption("modifiable", true)
   self.buf:setOption("buftype", "prompt")

   vim.fn.prompt_setprompt(self.buf.id, prompt or "> ")
   if cb then vim.fn.prompt_setcallback(self.buf.id, cb) end
   if int then vim.fn.prompt_setinterrupt(self.buf.id, int) end
   nvim.command("startinsert")
   return self
end
function Dialog:unsetPrompt()
   self.buf:setOption("modifiable", false)
   self.buf:setOption("buftype", "nofile")
   nvim.command("stopinsert")
   return self
end
function Dialog:close()
   self.win:close(true)
end

return dialog