local command = require("euclidian.lib.command")
local nvim = require("euclidian.lib.nvim")
local stl = require("euclidian.lib.statusline")
local tu = require("euclidian.lib.textutils")

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

stl.add(alwaysActive, empty, function(winid)
   local win = nvim.Window(winid)
   if not (win:getOption("number") or win:getOption("relativenumber")) then
      return (" "):rep(6)
   end

   local spaces = win:getOption("numberwidth") +
   tonumber(win:getOption("signcolumn"):match("yes:(%d+)")) or 0
   return tu.rightAlign(tostring(win:getBuf()), spaces) .. " "
end, "STLBufferInfo", true)

stl.add(active, inactive, function()
   return " " .. stl.getModeText() .. " "
end, stl.higroup)




























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
            vim.schedule(stl.updateWindow)
         end),
         onExit = function()
            if not gotDiff then
               filesChanged, insertions, deletions = nil, nil, nil
               vim.schedule(stl.updateWindow)
            end
         end,
      })
   end
   command.spawn({
      command = { "git", "branch", "--show-current" },
      cwd = vim.loop.cwd(),
      onStdoutLine = oneshot(function(ln)
         currentBranch = ln
         vim.schedule(stl.updateWindow)
      end),
   })
end
nvim.autocmd("BufWritePost", "*", updateGitStatusline)

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


stl.add(alwaysActive, empty, function(winid)
   local buf = nvim.Buffer(nvim.Window(winid):getBuf())
   if buf:getOption("buftype") == "terminal" then
      return ""
   end
   return " %f %m%r%h%w"
end, "STLFname", true)

stl.add(active, inactive, " %= ", "StatusLine")
stl.add(inactive, active, " %= ", "StatusLineNC")

local insFmt = tu.insertFormatted
local minWid = 100
stl.add(alwaysActive, empty, function(winid)
   local win, buf = nvim.winBuf(winid)

   local wid = win:getWidth()
   local line, col = unpack(win:getCursor())

   local out = {}

   local isShort = wid < minWid

   if stl.isActive(winid) then

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
   else
      insFmt(out, "Ln: %3d", line)
   end

   if #out > 1 then
      return table.concat(out, isShort and " " or " │ ") .. "  "
   else
      return "  " .. out[1] .. "  "
   end
end, "STLBufferInfo")

vim.schedule(function()
   updateGitStatusline()
   stl.updateWindow()
end)