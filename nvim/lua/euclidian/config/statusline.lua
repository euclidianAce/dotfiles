
local color = require("euclidian.lib.color")
local p = require("euclidian.config.colors")
local stl = require("euclidian.lib.statusline")
local nvim = require("euclidian.lib.nvim")

local hi = color.scheme.hi
local min, max = math.min, math.max
local function clamp(n, a, b)
   return min(max(n, a), b)
end

local darkenFactor = 2 ^ 7
local function invert(fgColor)
   local r, g, b = color.hexToRgb(fgColor)
   return {
      color.rgbToHex(
      r - clamp(darkenFactor, r * 0.16, r * 0.90),
      g - clamp(darkenFactor, g * 0.16, g * 0.90),
      b - clamp(darkenFactor, b * 0.16, b * 0.90)),

      fgColor,
   }
end

hi.STLBufferInfo = invert(hi.Comment[1])
hi.STLGit = invert(p.darkGreen)
hi.STLFname = invert(p.brightGray)
hi.STLNormal = invert(p.blue)
hi.STLInsert = invert(p.green)
hi.STLCommand = invert(p.purple)
hi.STLReplace = invert(p.red)
hi.STLVisual = invert(p.yellow)
hi.STLTerminal = invert(p.orange)

hi.StatusLine = hi.STLBufferInfo
hi.StatusLineNC = invert(p.gray)

stl.mode("n", "Normal", "STLNormal")
stl.mode("i", "Insert", "STLInsert")
stl.mode("c", "Command", "STLCommand")
stl.mode("r", "Confirm", "STLCommand")
stl.mode("R", "Replace", "STLReplace")
stl.mode("t", "Terminal", "STLTerminal")
stl.mode("v", "Visual", "STLVisual")
stl.mode("V", "Visual Line", "STLVisual")
stl.mode("", "Visual Block", "STLVisual")

local alwaysActive = { "Active", "Inactive" }
local active = { "Active" }
local inactive = { "Inactive" }
local empty = {}

local ti = table.insert
local sf = string.format
local function tiFmt(t, fmt, ...)
   ti(t, sf(fmt, ...))
end

stl.add(alwaysActive, empty, function(winid)
   local win = nvim.Window(winid)
   local spaces = win:getOption("numberwidth") + 1
   return (" "):rep(spaces) .. nvim.Window(winid):getBuf() .. " "
end, "STLBufferInfo")
stl.add(active, inactive, function()
   return "  " .. stl.getModeText() .. " "
end, stl.higroup)
stl.add(active, inactive, function()

   local branch = (vim.fn.FugitiveStatusline()):sub(6, -3)
   if branch == "" then
      return ""
   end
   return "  * " .. branch .. " "
end, "STLGit")
local maxFileNameLen = 20
stl.add(alwaysActive, empty, function(winid)
   local buf = nvim.Buffer(nvim.Window(winid):getBuf())
   if buf:getOption("buftype") == "terminal" then
      return ""
   end
   local fname = buf:getName()
   local cwd = vim.fn.getcwd()
   if fname:match("^" .. vim.pesc(cwd)) then
      fname = fname:sub(#cwd + 2, -1)
   end
   if #fname > maxFileNameLen then
      fname = " < " .. fname:sub(-maxFileNameLen, -1)
   end
   return "  " .. fname .. " "
end, "STLFname")
stl.add(alwaysActive, empty, "%m", "STLFname")
stl.add(active, inactive, "%r%h%w", "STLFname")

stl.add(active, inactive, " %= ", "StatusLine")
stl.add(inactive, active, " %= ", "StatusLineNC")

local minWid = 100
stl.add(alwaysActive, empty, function(winid)
   local win = nvim.Window(winid)
   local buf = nvim.Buffer(win:getBuf())

   local wid = win:getWidth()
   local pos = win:getCursor()

   local out = {}
   if stl.isActive(winid) then

      if wid > minWid then
         local expandtab = buf:getOption("expandtab")
         local num
         if expandtab then
            num = buf:getOption("shiftwidth")
         else
            num = buf:getOption("tabstop")
         end
         tiFmt(out, "%s (%d)", expandtab and "spaces" or "tabs", num)
      end


      local totalLines = #buf:getLines(0, -1, false)
      if wid > minWid then
         tiFmt(out, "Ln: %3d of %3d", pos[1], totalLines)
         tiFmt(out, "Col: %3d", pos[2] + 1)
         tiFmt(out, "%3d%%", pos[1] / totalLines * 100)
      else
         tiFmt(out, "Ln:%d C:%d", pos[1], pos[2])
      end
   else
      tiFmt(out, "Ln: %3d", pos[1])
   end
   if #out > 1 then
      return "│ " .. table.concat(out, " │ ") .. "  "
   else
      return "  " .. out[1] .. "  "
   end
end, "STLBufferInfo")