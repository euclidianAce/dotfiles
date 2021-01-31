
local color = require("euclidian.lib.color")
local p = require("euclidian.config.colors")
local stl = require("euclidian.lib.statusline")
local unpacker = require("euclidian.lib.util").unpacker
local a = vim.api

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

for m, txt, hl in unpacker({
      { "n", "Normal", "STLNormal" },
      { "i", "Insert", "STLInsert" },
      { "c", "Command", "STLCommand" },
      { "R", "Replace", "STLReplace" },
      { "t", "Terminal", "STLTerminal" },
      { "v", "Visual", "STLVisual" },
      { "V", "Visual Line", "STLVisual" },
      { "", "Visual Block", "STLVisual" },
   }) do
   stl.mode(m, txt, hl)
end

local alwaysActive = { "Active", "Inactive" }
local active = { "Active" }
local inactive = { "Inactive" }
local empty = {}

local ti = table.insert
local sf = string.format
local function tiFmt(t, fmt, ...)
   ti(t, sf(fmt, ...))
end

local winOption = a.nvim_win_get_option
stl.add(alwaysActive, empty, function(winid)
   local spaces = winOption(winid, "numberwidth") + winOption(winid, "foldcolumn") + 1
   return (" "):rep(spaces) .. a.nvim_win_get_buf(winid) .. " "
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


   local buf = a.nvim_win_get_buf(winid)
   local fname = a.nvim_buf_get_name(buf) or ""
   if fname:match("/bin/bash$") or #fname == 0 then
      return ""
   end
   if #fname > maxFileNameLen then
      fname = " <" .. fname:sub(-maxFileNameLen, -1)
   end
   return "  " .. fname .. " "
end, "STLFname")
stl.add(alwaysActive, empty, "%m", "STLFname")
stl.add(active, inactive, "%r%h%w", "STLFname")

stl.add(active, inactive, " %= ", "StatusLine")
stl.add(inactive, active, " %= ", "StatusLineNC")

local minWid = 100
stl.add(alwaysActive, empty, function(winid)
   local currentBuf = a.nvim_win_get_buf(winid)
   local cursorPos = a.nvim_win_get_cursor(winid)
   local wid = a.nvim_win_get_width(winid)
   local out = {}
   if stl.isActive(winid) then

      if wid > minWid then
         local expandtab = a.nvim_buf_get_option(currentBuf, "expandtab")
         local num
         if expandtab then num = a.nvim_buf_get_option(currentBuf, "shiftwidth")
         else num = a.nvim_buf_get_option(currentBuf, "tabstop")
         end
         tiFmt(out, "%s (%d)", expandtab and "spaces" or "tabs", num)
      end


      local totalLines = #a.nvim_buf_get_lines(currentBuf, 0, -1, false)
      if wid > minWid then
         tiFmt(out, "Ln: %3d of %3d", cursorPos[1], totalLines)
         tiFmt(out, "Col: %3d", cursorPos[2] + 1)
         tiFmt(out, "%3d%%", math.floor(cursorPos[1] / totalLines * 100))
      else
         tiFmt(out, "Ln:%d C:%d", cursorPos[1], cursorPos[2])
      end
   else
      tiFmt(out, "Ln: %3d", cursorPos[1])
   end

   return "  " .. table.concat(out, " | ") .. "  "
end, "STLBufferInfo")
