local command = require("euclidian.lib.command")

local nvim = require("euclidian.lib.nvim")
local lines = require("euclidian.lib.lines")
local tu = require("euclidian.lib.textutils")

local modeMap = {
   ["n"] = { " Normal ", "STLNormal" },
   ["i"] = { " Insert ", "STLInsert" },
   ["r"] = { " Confirm ", "STLCommand" },
   ["R"] = { " Replace ", "STLReplace" },
   ["v"] = { " Visual ", "STLVisual" },
   ["V"] = { " V·Line ", "STLVisual" },
   [""] = { " V·Block ", "STLVisual" },
   ["c"] = { " Command ", "STLCommand" },
   ["s"] = { " Select ", "STLVisual" },
   ["S"] = { " S·Line ", "STLVisual" },
   [""] = { " S·Block ", "STLVisual" },
   ["nt"] = { " N·Terminal ", "STLNormal" },
   ["t"] = { " I·Terminal ", "STLTerminal" },
   ["!"] = { " Shell ", "Comment" },
}

local function getModeText()
   local m = nvim.api.getMode().mode
   local found = modeMap[m] or
   modeMap[m:sub(1, 1)] or
   { " ??? ", "Error" }
   nvim.api.setHl(0, "STLModeText", { link = found[2] })
   return found[1]
end

local alwaysActive = { "Active", "Inactive" }
local active = { "Active" }
local inactive = { "Inactive" }
local empty = {}

local status = lines.new()

local currentTags = {}
local updateAll = vim.schedule_wrap(function()
   local currentWinId = nvim.api.getCurrentWin()
   local tags = {}
   for k, v in pairs(currentTags) do
      tags[k] = v
   end
   local winlist = nvim.api.listWins()
   for _, winid in ipairs(winlist) do
      local win = nvim.Window(winid)
      if win:isValid() and win:getConfig().relative == "" then
         tags.Active = currentWinId == winid
         tags.Inactive = currentWinId ~= winid





         status:setLocalStatus(tags, win)

      end
   end
end)

status:add(
alwaysActive, empty,
function(winid)
   local win, buf = nvim.winBuf(winid)

   local nu = win:getOption("number")
   local rnu = win:getOption("relativenumber")
   local scl = win:getOption("signcolumn"):match("yes:(%d+)")

   if not (nu or rnu or scl) then
      return (" % 4d "):format(buf.id)
   end

   local spaces = ((nu or rnu) and win:getOption("numberwidth") or 0) +
   (tonumber(scl) or 0)
   if spaces < 3 then
      return (" % 4d "):format(buf.id)
   end
   return tu.rightAlign(tostring(buf.id), spaces) .. " "
end,
"STLBufferInfo", true)


status:add(active, inactive, getModeText, "STLModeText")




























local gitActive, gitInactive = { "Git" }, { "Inactive" }
local maxBranchWid = 20
local currentBranch = ""

local function parseDiff(s)


   return s:match("(%d+) file"), s:match("(%d+) insert"), s:match("(%d+) delet")
end

local filesChanged, insertions, deletions
local function updateGitStatusline()
   local b = nvim.Buffer()
   if b:getOption("buftype") == "nofile" then
      return
   end
   local function oneshot(fn)
      local execd = false
      return function(...)
         if not execd then
            fn(...)
            execd = true
         end
      end
   end
   do
      local gotDiff = false
      command.spawn({
         command = { "git", "diff", "--shortstat" },
         cwd = vim.loop.cwd(),
         onStdoutLine = oneshot(function(ln)
            gotDiff = true
            filesChanged, insertions, deletions = parseDiff(ln)
            updateAll()
         end),
         onExit = function()
            if not gotDiff then
               filesChanged, insertions, deletions = nil, nil, nil
               updateAll()
            end
         end,
      })
   end
   command.spawn({
      command = { "git", "branch", "--show-current" },
      cwd = vim.loop.cwd(),
      onStdoutLine = oneshot(function(ln)
         currentBranch = ln
         updateAll()
      end),
   })
end
nvim.api.createAutocmd("BufWritePost", { pattern = "*", callback = updateGitStatusline })

status:add(gitActive, gitInactive, function()
   if currentBranch == "" then return "" end
   return " " .. currentBranch:sub(1, maxBranchWid)
end, "STLGit", true)
status:add(gitActive, gitInactive, function()
   if currentBranch == "" then return "" end
   return (" %s %s+ %s- "):format(filesChanged or "0", insertions or "0", deletions or "0")
end, "STLGit", true)

currentTags.Git = true
vim.keymap.set("n", "<F12>", function()
   currentTags.Git = not currentTags.Git
   updateAll()
end, {})


status:add(alwaysActive, empty, function(winid)
   local buf = nvim.Buffer(nvim.Window(winid):getBuf())
   if buf:getOption("buftype") == "terminal" then
      return ""
   end
   return " %f %m%r%h%w"
end, "STLFname", true)

status:add(active, inactive, " %= 🌌🐢🌌 %= ", "StatusLine")
status:add(inactive, active, " %= ", "StatusLineNC")

local insFmt = tu.insertFormatted
local minWid = 100
status:add(active, inactive, function(winid)
   local win, buf = nvim.winBuf(winid)

   local wid = win:getWidth()
   local line, col = unpack(win:getCursor())

   local out = {}

   local isShort = wid < minWid


   local expandtab = buf:getOption("expandtab")
   local num = expandtab and
   buf:getOption("shiftwidth") or
   buf:getOption("tabstop")
   insFmt(
   out, "%s(%d)",
   (expandtab and
   "spaces " or
   "tabs "):sub(1, isShort and 1 or -1),
   num)



   local totalLines = #buf:getLines(0, -1, false)
   if not isShort then
      insFmt(out, "Ln: %3d of %3d", line, totalLines)
      insFmt(out, "Col: %3d", col + 1)
      insFmt(out, "%3d%%", line / totalLines * 100)
   else
      insFmt(out, "%d,%d", line, col + 1)
   end

   if #out > 1 then
      return "  " .. table.concat(out, isShort and " " or " │ ") .. "  "
   else
      return "  " .. out[1] .. "  "
   end
end, "STLBufferInfo")

status:add(inactive, active, function(winid)
   return ("  Ln: %3d  "):format(nvim.Window(winid):getCursor()[1])
end, "STLBufferInfo")

vim.schedule(function()
   updateGitStatusline()
   updateAll()
end)

local group = nvim.createAugroup("Statusline")
group:add({ "WinEnter", "BufWinEnter" }, { callback = function() updateAll() end })