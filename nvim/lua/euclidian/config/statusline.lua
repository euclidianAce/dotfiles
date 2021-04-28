
local color = require("euclidian.lib.color")
local command = require("euclidian.lib.command")
local nvim = require("euclidian.lib.nvim")
local p = require("euclidian.config.colors")
local stl = require("euclidian.lib.statusline")

local hi = color.scheme.hi
local min, max = math.min, math.max
local function clamp(n, a, b)
   return min(max(n, a), b)
end

local darkenFactor = 128
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
hi.STLGit = invert(p.dark.green)
hi.STLFname = invert(p.bright.gray)
hi.STLNormal = invert(p.normal.blue)
hi.STLInsert = invert(p.normal.green)
hi.STLCommand = invert(p.normal.purple)
hi.STLReplace = invert(p.normal.red)
hi.STLVisual = invert(p.normal.yellow)
hi.STLTerminal = invert(p.normal.orange)

hi.StatusLine = hi.STLBufferInfo
hi.StatusLineNC = invert(p.normal.gray)

stl.mode("n", "Normal", "STLNormal")
stl.mode("i", "Insert", "STLInsert")
stl.mode("c", "Command", "STLCommand")
stl.mode("r", "Confirm", "STLCommand")
stl.mode("R", "Replace", "STLReplace")
stl.mode("t", "Terminal", "STLTerminal")
stl.mode("v", "Visual", "STLVisual")
stl.mode("V", "V·Line", "STLVisual")
stl.mode("", "V·Block", "STLVisual")

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
end, "STLBufferInfo", true)
stl.add(active, inactive, function()
   return " " .. stl.getModeText() .. " "
end, stl.higroup)


do
   local gitActive, gitInactive = { "Git" }, { "Inactive" }
   local maxBranchWid = 20
   local currentBranch = ""

   local function parseDiff(s)

      return s:match("(%d+) files changed, (%d+) insertions%(%+%), (%d+) deletions")
   end

   local filesChanged, insertions, deletions = "0", "0", "0"
   nvim.autocmd("VimEnter,BufWritePost", "*", function()
      local b = nvim.Buffer()
      if b:getOption("buftype") == "nofile" then
         return
      end
      command.spawn({
         command = { "git", "diff", "--shortstat" },
         cwd = vim.loop.cwd(),
         onStdoutLine = function(ln)
            filesChanged, insertions, deletions = parseDiff(ln)
            vim.schedule(stl.updateWindow)
         end,
      })
      command.spawn({
         command = { "git", "branch", "--show-current" },
         cwd = vim.loop.cwd(),
         onStdoutLine = function(ln)
            currentBranch = ln
            vim.schedule(stl.updateWindow)
         end,
      })
   end)

   stl.add(gitActive, gitInactive, function()
      if currentBranch == "" then return "" end
      return " " .. currentBranch:sub(1, maxBranchWid)
   end, "STLGit", true)
   stl.add(gitActive, gitInactive, function()
      if currentBranch == "" then return "" end
      return (" ~%s +%s -%s "):format(filesChanged or "0", insertions or "0", deletions or "0")
   end, "STLGit", true)

   stl.toggleTag("Git")
   nvim.setKeymap("n", "<F12>", stl.tagToggler("Git"), { noremap = true })
end

stl.add(alwaysActive, empty, function(winid)
   local buf = nvim.Buffer(nvim.Window(winid):getBuf())
   if buf:getOption("buftype") == "terminal" then
      return ""
   end
   return " %f %m%r%h%w"
end, "STLFname", true)

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
         local num = expandtab and
         buf:getOption("shiftwidth") or
         buf:getOption("tabstop")
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