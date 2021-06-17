local a = vim.api
local nvim = require("euclidian.lib.nvim")

local TextRegion = {Position = {}, }











local Dialog = {Opts = {Center = {}, }, }

























local bufs = setmetatable({}, { __mode = "k", __index = function() return nvim.Buffer(-1) end })
local wins = setmetatable({}, { __mode = "k", __index = function() return nvim.Window(-1) end })
local links = setmetatable({}, { __mode = "k", __index = function(self, k)
   local t = {}
   rawset(self, k, t)
   return t
end, })
local origOpts = setmetatable({}, { __mode = "k" })

local function copyCenterOpts(o)
   local cpy = {}
   if not o then
      cpy.vertical = false
      cpy.horizontal = false
   elseif type(o) == "boolean" then
      cpy.vertical = true
      cpy.horizontal = true
   else
      cpy.vertical = o.vertical
      cpy.horizontal = o.horizontal
   end
   return cpy
end

local function copyOpts(o)

   return {
      wid = o.wid,
      hei = o.hei,
      row = o.row,
      col = o.col,
      notMinimal = o.notMinimal,
      interactive = o.interactive,
      hidden = o.hidden,
      border = o.border,
      centered = copyCenterOpts(o.centered),
   }
end

local dialog = {
   Dialog = Dialog,
   TextRegion = TextRegion,
}

local BufOrId = {}

local function getBuf(maybeBuf)
   if not maybeBuf then
      return nvim.createBuf(false, true)
   elseif type(maybeBuf) == "table" then
      if not maybeBuf:isValid() then
         return nvim.createBuf(false, true)
      end
      return maybeBuf
   else
      return nvim.Buffer(maybeBuf)
   end
end

local defaultBorderHighlight = "Normal"
local defaultBorder = {
   { "╭", defaultBorderHighlight },
   { "─", defaultBorderHighlight },
   { "╮", defaultBorderHighlight },
   { "│", defaultBorderHighlight },
   { "╯", defaultBorderHighlight },
   { "─", defaultBorderHighlight },
   { "╰", defaultBorderHighlight },
   { "│", defaultBorderHighlight },
}

local floor, max, min =
math.floor, math.max, math.min

local function clamp(n, lower, upper)
   return min(max(lower, n), upper)
end




local function convertNum(n, base)
   if n < 0 then
      return floor(base + n)
   elseif n < 1 then
      return floor(base * n)
   else
      return floor(clamp(n, 1, base))
   end
end

function dialog.optsToWinConfig(opts)
   local cfg = {
      relative = "editor",
      style = not opts.notMinimal and "minimal" or nil,
      border = opts.border or defaultBorder,
      focusable = opts.interactive,
   }
   local ui = nvim.ui()

   local center = copyCenterOpts(opts.centered)

   if center.horizontal then
      cfg.width = convertNum(
      assert(opts.wid, "horizontally centered dialogs require a 'wid' field"),
      ui.width)

      cfg.col = math.floor((ui.width - cfg.width) / 2)
   else
      cfg.col = convertNum(assert(opts.col, "non-centered dialogs require a 'col' field"), ui.width)
      cfg.width = convertNum(assert(opts.wid, "non-centered dialogs require a 'wid' field"), ui.width)
   end

   if center.vertical then
      cfg.height = convertNum(
      assert(opts.hei, "vertically centered dialogs require a 'hei' field"),
      ui.height)

      cfg.row = math.floor((ui.height - cfg.height) / 2)
   else
      cfg.row = convertNum(assert(opts.row, "non-centered dialogs require a 'row' field"), ui.height)
      cfg.height = convertNum(assert(opts.hei, "non-centered dialogs require a 'hei' field"), ui.height)
   end

   return cfg
end

local function setupBuf(opts, maybeBuf)
   local buf = getBuf(maybeBuf)

   if buf:getOption("buftype") == "" then
      buf:setOption("buftype", "nofile")
   end

   buf:setOption("modifiable", false)
   if opts.ephemeral then
      buf:setOption("bufhidden", "wipe")
   end

   return buf
end

local function setupWin(opts, buf)
   if opts.hidden then
      return nvim.Window(-1)
   end
   local cfg = dialog.optsToWinConfig(opts)
   local win = nvim.openWin(buf, opts.interactive, cfg)

   if win:isValid() then
      win:setOption("winhighlight", "Normal:Normal,NormalFloat:Normal")
   end

   return win
end

function dialog.new(opts, maybeBuf)
   opts = opts or {}
   local buf = setupBuf(opts, maybeBuf)
   local win = setupWin(opts, buf)

   local d = setmetatable({ regions = {} }, { __index = Dialog })

   bufs[d] = buf
   wins[d] = win
   origOpts[d] = copyOpts(opts)

   return d
end


function Dialog:link(...)
   local ls = links[self]
   for i = 1, select("#", ...) do
      local d = select(i, ...)
      if d then
         table.insert(ls, d)
      end
   end
   return self
end
function Dialog:unlink(...)
   local ls = links[self]
   for argI = 1, select("#", ...) do
      local d = select(argI, ...)
      for i, v in ipairs(ls) do
         if v == d then
            table.remove(ls, i)
         end
      end
   end
end

function Dialog:origOpts()
   return copyOpts(origOpts[self])
end
function Dialog:buf()
   return bufs[self]
end
function Dialog:ensureBuf()
   if bufs[self]:isValid() then
      return bufs[self]
   end
   bufs[self] = setupBuf(self:origOpts())
   assert(bufs[self]:isValid(), "Dialog:ensureBuf() produced an invalid buffer")
   return bufs[self]
end
function Dialog:win()
   return wins[self]
end
function Dialog:show(dontSwitch)
   if wins[self]:isValid() then

      return self
   end

   if not self:buf():isValid() then
      bufs[self] = setupBuf(origOpts[self])
   end

   local opts = copyOpts(origOpts[self])
   opts.hidden = false
   opts.interactive = not dontSwitch

   wins[self] = setupWin(opts, self:ensureBuf())

   return self
end
function Dialog:ensureWin()

   self:show(true)
   assert(wins[self]:isValid(), "Dialog:ensureWin() produced an invalid window")
   return wins[self]
end

function Dialog:isModifiable()
   return self:ensureBuf():getOption("modifiable")
end
function Dialog:setModifiable(to)
   self:ensureBuf():setOption("modifiable", to)
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
      self:ensureBuf():setLines(0, -1, false, txt)
   end)
end
function Dialog:appendLines(txt)
   return self:modify(function()
      bufs[self]:setLines(-1, -1, false, txt)
   end)
end
function Dialog:setLine(num, ln)
   return self:modify(function()
      bufs[self]:setLines(num, num + 1, false, { ln })
   end)
end
function Dialog:setText(edits)

   return self:modify(function()
      local b = bufs[self]
      for _, edit in ipairs(edits) do
         b:setText(edit[2], edit[3], edit[4], edit[5], { edit[1] })
      end
   end)
end
function Dialog:setCursor(row, col)
   self:ensureWin():setCursor({ row or 1, col or 0 })
   return self
end
function Dialog:getCursor()
   local pos = self:ensureWin():getCursor()
   return pos[1], pos[2]
end
function Dialog:getLine(n)
   return self:ensureBuf():getLines(n - 1, n, false)[1]
end
function Dialog:getCurrentLine()
   return self:getLine((self:getCursor()))
end
function Dialog:getLines(minimum, maximum)
   return self:ensureBuf():getLines(minimum or 0, maximum or -1, false)
end
function Dialog:setWinConfig(c)
   local win = self:ensureWin()
   local orig = win:getConfig()
   local new = {}
   for k, v in pairs(orig) do
      new[k] = (c)[k] or v
   end
   win:setConfig(new)
   return self
end
function Dialog:moveAbsolute(row, col)
   local win = self:ensureWin()
   local c = win:getConfig()
   c.row = row
   c.col = col
   win:setConfig(c)
   return self
end
function Dialog:moveRelative(drow, dcol)
   local win = self:ensureWin()
   local c = win:getConfig()
   c.row = c.row + drow
   c.col = c.col + dcol
   win:setConfig(c)
   return self
end
function Dialog:setOpts(opts)
   return self:setWinConfig(dialog.optsToWinConfig(opts))
end
function Dialog:addKeymap(mode, lhs, rhs, opts)
   self:ensureBuf():setKeymap(mode, lhs, rhs, opts)
   return self
end
function Dialog:delKeymap(mode, lhs)
   self:ensureBuf():delKeymap(mode, lhs)
   return self
end
function Dialog:setPrompt(prompt, cb, int)
   local buf = self:ensureBuf()
   buf:setOption("modifiable", true)
   buf:setOption("buftype", "prompt")

   vim.fn.prompt_setprompt(buf.id, prompt or "> ")
   if cb then vim.fn.prompt_setcallback(buf.id, cb) end
   if int then vim.fn.prompt_setinterrupt(buf.id, int) end
   nvim.command("startinsert")
   return self
end
function Dialog:unsetPrompt()
   local buf = self:ensureBuf()
   buf:setOption("modifiable", false)
   buf:setOption("buftype", "nofile")
   nvim.command("stopinsert")
   return self
end
function Dialog:fitText(minWid, minHei, maxWid, maxHei)
   local lines = self:ensureBuf():getLines(0, -1, false)
   local line = ""
   for _, ln in ipairs(lines) do
      if #ln > #line then
         line = ln
      end
   end
   local ui = nvim.ui()
   local win = self:ensureWin()
   win:setHeight(clamp(#lines, minHei or 1, maxHei or ui.height))
   win:setWidth(clamp(#line, minWid or 1, maxWid or ui.width))
   return self
end
function Dialog:setWinSize(width, height)
   local win = self:ensureWin()
   local ui = nvim.ui()
   if height then win:setHeight(clamp(height, 1, ui.height)) end
   if width then win:setWidth(clamp(width, 1, ui.width)) end
   return self
end
function Dialog:fitTextPadded(colPad, rowPad, minWid, minHei, maxWid, maxHei)
   local lines = self:ensureBuf():getLines(0, -1, false)
   local line = ""
   for _, ln in ipairs(lines) do
      if #ln > #line then
         line = ln
      end
   end
   local ui = nvim.ui()
   local win = self:ensureWin()
   win:setHeight(clamp(
   #lines + (rowPad or 0),
   minHei or 1,
   maxHei or ui.height))

   win:setWidth(clamp(
   #line + (colPad or 0),
   minWid or 1,
   maxWid or ui.width))

   return self
end
function Dialog:center()
   local ui = nvim.ui()
   local win = self:ensureWin()
   local cfg = win:getConfig()
   win:setConfig({
      relative = "editor",
      col = math.floor((ui.width - cfg.width) / 2),
      row = math.floor((ui.height - cfg.height) / 2),
      width = cfg.width,
      height = cfg.height,
   })
   return self
end
function Dialog:centerHorizontal()
   local ui = nvim.ui()
   local win = self:ensureWin()
   local cfg = win:getConfig()
   win:setConfig({
      relative = "editor",
      col = math.floor((ui.width - cfg.width) / 2),
      row = cfg.row,
      width = cfg.width,
      height = cfg.height,
   })
   return self
end
function Dialog:centerVertical()
   local ui = nvim.ui()
   local win = self:ensureWin()
   local cfg = win:getConfig()
   win:setConfig({
      relative = "editor",
      col = cfg.col,
      row = math.floor((ui.height - cfg.height) / 2),
      width = cfg.width,
      height = cfg.height,
   })
   return self
end
function Dialog:hide()
   local w = self:win()
   if not w:isValid() then
      return self
   end
   w:hide()
   return self
end
function Dialog:focus()
   a.nvim_set_current_win(self:ensureWin().id)
   return self
end
function Dialog:close()
   local w = self:win()
   if w:isValid() then
      w:close(true)
   end
end

local linkedFns = {
   hide = true,
   close = true,
   show = true,
}
local _Dialog = Dialog
for k in pairs(linkedFns) do
   local oldFn = _Dialog[k]
   _Dialog[k] = function(self, ...)
      for _, d in ipairs(links[self]) do
         oldFn(d, ...)
      end
      return oldFn(self, ...)
   end
end

local function cmpPos(lhs, rhs)
   return lhs.line == rhs.line and
   lhs.char < rhs.char or
   lhs.line < rhs.line
end

function Dialog:claimRegion(start, nlines, nchars)
   local r = setmetatable({
      start = { line = start.line, char = start.char },
      finish = {
         line = start.line + nlines,
         char = nlines > 0 and
         nchars or
         start.char + nchars,
      },
      nlines = nlines,
      nchars = nchars,
   }, {
      __index = TextRegion,
      parent = self,
   })
   for i = 1, #self.regions - 1 do
      local cur, nxt = self.regions[i], self.regions[i + 1]
      if cmpPos(cur.finish, r.start) and cmpPos(r.finish, nxt.start) then
         table.insert(self.regions, i, r)
         return r
      end
   end
   table.insert(self.regions, r)
   return r
end

local TextRegionMt = {}





local function getmt(tr)
   return getmetatable(tr)
end

local function pad(s, len)
   return s .. (" "):rep(len - #s)
end

function TextRegion:set(s, clear)
   local d = getmt(self).parent
   local buf = d:ensureBuf()
   local inputLns = { unpack(vim.split(s, "\n"), 1, self.nlines + 1) }

   d:modify(function()

      if self.nlines == 1 and self.start.char == 0 then
         buf:setLines(
         self.start.line,
         self.finish.line + 1,
         false,
         inputLns)

         return
      end


      if self.start.char ~= 0 and self.nlines == 0 then

         local txt = inputLns[1]

         local sRow = self.start.line
         local sCol = self.start.char

         local nchars = math.min(#txt, self.nchars)
         local eCol
         if clear then
            txt = pad(txt, self.nchars)
            eCol = sCol + self.nchars
         else
            txt = txt:sub(1, nchars)
            eCol = sCol + nchars
         end

         buf:setText(
         sRow, sCol,
         sRow, eCol,
         { txt })


         return
      end

      local currentLines = buf:getLines(self.start.line, self.finish.line + 1, false)
      if self.nlines > 0 then
         currentLines[1] = (currentLines[1] or ""):sub(1, self.start.char) .. inputLns[1]
      end

      local batchIncludesLastLine = true

      if self.nlines > 1 and self.nchars > 0 then
         batchIncludesLastLine = false
         local txt = table.remove(currentLines)

         local nchars = math.min(#txt, self.nchars)
         local eCol
         if clear then
            txt = pad(txt, self.nchars)
            eCol = self.nchars
         else
            txt = txt:sub(1, nchars)
            eCol = nchars
         end

         buf:setText(
         self.finish.line, 0,
         self.finish.line, eCol,
         { txt })

      end

      buf:setLines(
      self.start.line,
      self.finish.line + (batchIncludesLastLine and 1 or 0),
      false,
      currentLines)

   end)
end

for name, fn in pairs(TextRegion) do
   (TextRegion)[name] = function(self, ...)
      if getmt(self).unclaimed then
         error("TextRegion has already been unclaimed", 2)
      end
      return fn(self, ...)
   end
end

function TextRegion:unclaim()
   local mt = getmt(self)
   if mt.unclaimed then return end
   mt.unclaimed = true
   local d = mt.parent
   for i, v in ipairs(d.regions) do
      if self == v then
         table.remove(d.regions, i)
         return
      end
   end
end

return dialog