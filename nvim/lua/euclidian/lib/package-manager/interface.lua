
local packagespec = require("euclidian.lib.package-manager.packagespec")
local cmd = require("euclidian.lib.package-manager.cmd")
local set = require("euclidian.lib.package-manager.set")
local window = require("euclidian.lib.window")
local dialog = require("euclidian.lib.dialog")
local ev = require("euclidian.lib.ev")

local Spec = packagespec.Spec
local Dialog = dialog.Dialog

local interface = {}

local function longest(lines)
   local idx, len = 1, #lines[1]
   for i = 2, #lines do
      if len < #lines[i] then
         len = #lines[i]
         idx = i
      end
   end
   return idx, lines[idx]
end

local floor, ceil, max, min =
math.floor, math.ceil, math.max, math.min
local function getWinSize(wid, hei)
   local ui = window.ui()

   local minWid = floor(ui.width * .25)
   local minHei = floor(ui.height * .25)

   local maxWid = floor(ui.width * .90)
   local maxHei = floor(ui.height * .90)

   wid = min(max(minWid, wid), maxWid)
   hei = min(max(minHei, hei), maxHei)

   return floor((ui.width - wid) / 2), floor((ui.height - hei) / 2), wid, hei
end

local function getWinSizeTable(width, height)
   local col, row, wid, hei = getWinSize(width, height)
   return { col = col, row = row, wid = wid, hei = hei }
end

local function accommodateText(d)
   local lines = d:getLines()
   local twid = longest(lines)
   local thei = #lines

   local col, row, wid, hei = getWinSize(twid, thei)
   d:setWin({ col = col, row = row, wid = wid, hei = hei })
end

function interface.displaySets()
   local sets = set.list()
   local _, longestSetName = longest(sets)

   local d = dialog.new(getWinSize(#longestSetName + 3, #sets + 3))
   d:setLines(sets)

   return d
end

local currentDialog

function interface._step(data)
   local ok, err = coroutine.resume(currentDialog, data)
   if coroutine.status(currentDialog) == "dead" then
      currentDialog = nil
   end
   if not ok then
      error(err)
   end
end

local function getLastLine(txt)
   return txt:match("[\n]*([^\n]*)[\n]*$")
end

math.randomseed(os.time())

local stepCmd = "<cmd>lua require[[euclidian.lib.package-manager.interface]]._step()<cr>"
local stepCmdFmt = "<cmd>lua require[[euclidian.lib.package-manager.interface]]._step(%q)<cr>"

local function makeTitle(txt, width)
   local chars = width - #txt - 2
   return ("%s %s %s"):format(
("="):rep(floor(chars / 2)),
txt,
("="):rep(ceil(chars / 2)))

end

local function setCurrentDialog(fn)
   currentDialog = coroutine.create(fn)
   coroutine.resume(currentDialog)
end

local function setComparator(a, b)
   return a:title() < b:title()
end

local defaultKeymapOpts = { silent = true, noremap = true }

local function runForEachPkg(getCmd)
   setCurrentDialog(function()
      local d = interface.displaySets()
      d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)
      coroutine.yield()
      d:delKeymap("n", "<cr>")
      local ln = d:getCursor()
      local selected = d:getLine(ln)

      local textSegments = {}

      local selectedSet = set.load(selected)
      table.sort(selectedSet, setComparator)

      local maxCmds = 4
      local runningCmds = 0
      local jobs = {}
      local longestTitle = 0

      for i, p in ipairs(selectedSet) do
         local title = p:title()
         local segment = { title, "", "..." }
         if #title > longestTitle then
            longestTitle = #title
         end
         local command = getCmd(p)
         if command then

            local function updateStatus(status)
               segment[2] = status
            end
            local function updateText(txt)
               segment[3] = getLastLine(txt)
            end
            table.insert(jobs, function(t)
               cmd.runEvented({
                  command = command,
                  cwd = p:location(),
                  on = {
                     start = function()
                        runningCmds = runningCmds + 1
                        updateStatus("started")
                     end,
                     close = function()
                        runningCmds = runningCmds - 1
                        updateStatus("finished")
                     end,
                     stdout = updateText,
                     stderr = updateText,
                  },
                  thread = t,
               })
            end)
         else
            segment[2] = "installed"
         end
         textSegments[i + 1] = segment
      end

      local ui = window.ui()
      local width = floor(ui.width * .9)
      d:setWin(getWinSizeTable(width, #textSegments + 1))
      textSegments[1] = {
         makeTitle("Package", longestTitle),
         makeTitle("Status", 10),
         makeTitle("Output", width - longestTitle - 18),
      }
      textSegments[#textSegments + 1] = textSegments[1]

      local lines = {}
      local fmtStr = " %" .. tostring(longestTitle) .. "s | %10s | %s"
      local function updateText()
         for i, segment in ipairs(textSegments) do
            lines[i] = fmtStr:format(segment[1], segment[2], segment[3])
         end
         d:setLines(lines)
      end
      updateText()
      local function jobsLeft()
         return not (runningCmds == 0 and #jobs == 0)
      end

      if jobsLeft() then
         ev.loop(function()
            local t = coroutine.running()
            local function startJobs()
               ev.wait()
               while runningCmds < maxCmds and #jobs > 0 do
                  table.remove(jobs, math.random(1, #jobs))(t)
               end
               ev.wait()
            end

            startJobs()

            while jobsLeft() do
               ev.wait()
               updateText()
               startJobs()
            end
            updateText()

            d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)
         end):asyncRun(150)
      else
         d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)
      end

      coroutine.yield()
      d:close()
   end)
end

function interface.installSet()
   runForEachPkg(function(p)
      if not p:isInstalled() then
         return p:installCmd()
      end
   end)
end

function interface.updateSet()
   runForEachPkg(function(p)
      return { "echo", "git", "pull", "(" .. p:title() .. ")" }
   end)
end

local function ask(d, question, confirm, deny)
   d:setLines({
      question,
      confirm or "Yes",
      deny or "No",
   })






   d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)

   local ln
   repeat
      coroutine.yield()
      ln = d:getCursor()
   until ln > 1

   d:delKeymap("n", "<cr>")

   return ln == 2
end

local function setChecklist(d, s)
   local text = {}
   for _, p in ipairs(s) do
      table.insert(text, "[ ] " .. p:title())
   end
   d:setLines(text)
   accommodateText(d)

   d:addKeymap("n", "C", stepCmdFmt:format("C"), defaultKeymapOpts)
   d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)

   while true do
      local res = coroutine.yield()
      if not res then          break end
      local ln = d:getCursor()
      local line = d:getLine(ln)
      d:setText({
         { line:match("^%[%*") and " " or "*", ln - 1, 1, ln - 1, 2 },
      })
   end

   d:delKeymap("n", "C")
   local checked = {}
   local lines = d:getLines(1, -1)
   for i, line in ipairs(lines) do
      if line:match("^%[%*") then
         table.insert(checked, s[i + 1])
      end
   end

   return checked
end

function interface.addPackage()
   setCurrentDialog(function()
      local d = interface.displaySets()
      d:addKeymap("n", "<cr>", stepCmd, defaultKeymapOpts)
      coroutine.yield()

      local selectedSet
      local newPackage = {}

      do
         local ln = d:getCursor()
         local selected = d:getLine(ln)
         print("selected", selected)
         selectedSet = set.load(selected)
         table.sort(selectedSet, setComparator)

         local text = {}
         for kind in pairs(packagespec.kinds) do
            table.insert(text, kind)
         end
         table.sort(text)

         d:setLines(text)
         coroutine.yield()
         d:delKeymap("n", "<cr>")
      end

      do
         local ln = d:getCursor()
         local selectedKind = d:getLine(ln)
         newPackage.kind = selectedKind
         print("kind of new package: ", selectedKind)

         d:setLines({})
         local promptText
         if selectedKind == "git" then
            promptText = "git repo: "
         elseif selectedKind == "local" then
            promptText = "local path: "
         end
         local result
         d:setPrompt(promptText, function(txt)
            result = txt
            interface._step()
         end)
         coroutine.yield()
         d:unsetPrompt()
      end

      if ask(d, "Does this package depend on any other packages?") then
         local _dependencies = setChecklist(d, selectedSet)

      end

      if ask(d, "Do any other packages depend on this package?") then
         local _dependents = setChecklist(d, selectedSet)

      end



      coroutine.yield()
      d:close()
   end)
end

vim.api.nvim_command([[command! -nargs=0 Ptest lua req'euclidian.lib.package-manager.interface'.addPackage()]])

return interface
