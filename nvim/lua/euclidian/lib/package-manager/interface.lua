
local packagespec = require("euclidian.lib.package-manager.packagespec")
local cmd = require("euclidian.lib.package-manager.cmd")
local set = require("euclidian.lib.package-manager.set")
local window = require("euclidian.lib.window")
local dialog = require("euclidian.lib.dialog")
local ev = require("euclidian.lib.ev")

local Spec = packagespec.Spec

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

local function getWinSize(wid, hei)
   local ui = window.ui()
   local minWid = math.floor(ui.width / 4)
   local minHei = math.floor(ui.height / 4)

   wid = math.max(minWid, wid)
   hei = math.max(minHei, hei)

   return math.floor((ui.width - wid) / 2), math.floor((ui.height - hei) / 2), wid, hei
end

local function getWinSizeTable(width, height)
   local col, row, wid, hei = getWinSize(width, height)
   return { col = col, row = row, wid = wid, hei = hei }
end

function interface.displaySets()
   local sets = set.list()
   local _, longestSetName = longest(sets)

   local d = dialog.new(getWinSize(#longestSetName + 3, #sets + 3))
   d:setLines(sets)

   return d
end

local currentDialog

function interface._step()
   coroutine.resume(currentDialog)
end

local function getLastLine(txt)
   return txt:match("[\n]*([^\n]*)[\n]*$")
end

math.randomseed(os.time())

local stepCmd = "<cmd>lua require[[euclidian.lib.package-manager.interface]]._step()<cr>"

local function makeTitle(txt, width)
   local chars = width - #txt - 2
   return ("%s %s %s"):format(
("="):rep(math.floor(chars / 2)),
txt,
("="):rep(math.ceil(chars / 2)))

end

local function setCurrentDialog(fn)
   currentDialog = coroutine.create(fn)
   coroutine.resume(currentDialog)
end

local function runForEachPkg(getCmd)
   setCurrentDialog(function()
      local d = interface.displaySets()
      d:addKeymap("n", "<cr>", stepCmd, { silent = true, noremap = true })
      coroutine.yield()
      d:delKeymap("n", "<cr>")
      local ln = d:getCursor()
      local selected = d:getLine(ln)

      local textSegments = {}

      local selectedSet = set.load(selected)
      table.sort(selectedSet, function(a, b)
         return a:title() < b:title()
      end)

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
      local width = math.floor(ui.width * .9)
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

            d:addKeymap("n", "<cr>", stepCmd, { silent = true, noremap = true })
         end):asyncRun(150)
      else
         d:addKeymap("n", "<cr>", stepCmd, { silent = true, noremap = true })
      end

      coroutine.yield()
      d:close()

      currentDialog = nil
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

return interface
