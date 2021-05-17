
local nvim = require("euclidian.lib.nvim")
local command = require("euclidian.lib.command")
local dialog = require("euclidian.lib.dialog")
local packagespec = require("euclidian.lib.package-manager.packagespec")
local set = require("euclidian.lib.package-manager.set")
local z = require("euclidian.lib.async.zig")

local NilFrame = {}

local actions = {
   maxConcurrentJobs = 2,
   listSets = nil,
   update = nil,
   install = nil,
   add = nil,
}

local Spec = packagespec.Spec
local Dialog = dialog.Dialog
local function setCmp(a, b)
   return a:title() < b:title()
end

local function createDialog(fn)
   return function()
      local d = dialog.new({
         wid = 35, hei = 17, centered = true,
         interactive = true,
         ephemeral = true,
      })
      d:win():setOption("wrap", false)
      return z.async(fn, d)
   end
end

local function waitForKey(d, ...)
   local keys = { ... }
   local function delKeymaps()
      vim.schedule(function()
         for _, key in ipairs(keys) do
            d:delKeymap("n", key)
         end
      end)
   end
   local pressed
   local me = assert(z.currentFrame(), "attempt to waitForKey not in a coroutine")
   vim.schedule(function()
      for _, key in ipairs(keys) do
         d:addKeymap("n", key, function()
            pressed = key
            delKeymaps()
            z.resume(me)
         end, { noremap = true, silent = true })
      end
   end)
   z.suspend()
   return pressed
end

actions.listSets = createDialog(function(d)

   repeat
      local pkgs = set.list()
      table.sort(pkgs)

      d:setLines(pkgs):
      fitText(35, 17):
      center()

      if waitForKey(d, "<cr>", "<bs>") == "<bs>" then
         break
      end

      local choice = d:getCurrentLine()
      local loaded = set.load(choice)

      table.sort(loaded, setCmp)
      local txt = {}

      for i, v in ipairs(loaded) do
         txt[i] = v:title()
      end

      d:setLines(txt):
      fitText(35, 17):
      center()

   until waitForKey(d, "<cr>", "<bs>") == "<cr>"

   d:close()
end)

local function chooseAndLoadSet(d)
   local pkgs = set.list()
   table.sort(pkgs)

   d:setLines(pkgs):
   fitText(35, 17):
   center()

   waitForKey(d, "<cr>")

   local name = d:getCurrentLine()
   return set.load(name), name
end

local function prompt(d, promptText)
   local f = z.currentFrame()
   local val
   d:setPrompt(promptText, function(s)
      print("Prompt: ", s)
      val = s
      d:unsetPrompt()
      vim.schedule(function()
         z.resume(f)
      end)
   end)
   z.suspend()
   return val
end

local function yesOrNo(d, pre, affirm, deny)
   affirm = affirm or "yes"
   deny = deny or "no"
   d:setLines({
      pre,
      affirm,
      deny,
   })
   local ln
   repeat
      waitForKey(d, "<cr>")
      ln = d:getCursor()
   until ln > 1
   return ln == 2
end

local checkKey = "a"
local function checklist(d, pre, opts)
   d:buf():setOption("number", true)
   d:buf():setOption("relativenumber", true)
   local lines = {}
   for i, v in ipairs(opts) do
      lines[i] = "[ ] " .. v
   end
   table.insert(lines, 1, pre)
   d:setLines(lines):fitText():center()
   d:addKeymap("n", checkKey, function()
      local ln = d:getCursor()
      local l = d:getLine(ln)
      d:setText({ {
         l:match("^%[%*") and " " or "*", ln - 1, 1, ln - 1, 2,
      }, })
   end, { silent = true, noremap = true })
   waitForKey(d, "<cr>")
   d:delKeymap("n", checkKey)
   local selected = {}
   for i, v in ipairs(d:getLines(1, -1)) do
      if v:match("^%[%*") then
         table.insert(selected, i)
      end
   end
   d:buf():setOption("number", false)
   d:buf():setOption("relativenumber", false)
   return selected
end

do
   local function getPkgNames(s)
      local pkgNames = {}
      for i, v in ipairs(s) do
         pkgNames[i] = v:title()
      end
      return pkgNames
   end

   local function askForDependents(d, s, p)
      if yesOrNo(d, "Does other packages depend on this package?") then
         local deps = checklist(d, "Dependents:", getPkgNames(s))
         for _, idx in ipairs(deps) do
            table.insert(p.dependents, s[idx])
         end
      end
   end

   local function askForDependencies(d, s, p)
      if yesOrNo(d, "Does this package depend on other packages?") then
         local deps = checklist(d, "Dependencies:", getPkgNames())
         for _, idx in ipairs(deps) do
            if not s[idx].dependents then
               s[idx].dependents = {}
            end
            table.insert(s[idx].dependents, p)
         end
      end
   end

   local function addVimPlugPackage()
      print("Vim Plug Package: not yet implemented")


























   end
   local function addPackerPackage()
      print("Packer Package: not yet implemented")

   end
   local function addGitPackage(d, s)
      d:setLines({})
      local repo = prompt(d, "Repo: ")
      local pkgNames = {}
      for i, v in ipairs(s) do
         pkgNames[i] = v:title()
      end
      local p = {
         kind = "git",
         dependents = {},
         repo = repo,
      }
      askForDependencies(d, s, p)
      askForDependents(d, s, p)
      table.insert(s, p)
   end
   local function addLocalPackage(d, s)
      d:setLines({})
      local path = prompt(d, "Path: ")
      local p = {
         kind = "local",
         dependents = {},
         path = path,
      }
      table.insert(s, p)
   end




   local handlers = {
      [1] = addVimPlugPackage,
      [2] = addPackerPackage,
      [3] = addGitPackage,
      [4] = addLocalPackage,

   }

   actions.add = createDialog(function(d)
      local loaded, name = chooseAndLoadSet(d)

      d:setLines({
         "Add new package:",
         "  from Vim-Plug expression",
         "  from Packer expression",
         "  git",
         "  local",

      }):fitText(35):center()

      local ln
      repeat
         waitForKey(d, "<cr>")
         ln = d:getCursor()
      until ln > 1

      set.save("." .. name .. "__bak", loaded)
      handlers[ln - 1](d, loaded)
      set.save(name, loaded)
      d:close()
   end)
end
















local titleWidth = 35
local scheduleWrap = vim.schedule_wrap


local function runCmdForEachPkg(d, getcmd, loaded)
   local mainTask = z.currentFrame()

   local jobqueue = {}
   local running = 0

   for i, pkg in ipairs(loaded) do
      local cmd = getcmd(pkg)
      if cmd then
         local r = d:claimRegion(
         { line = i - 1, char = titleWidth + 1 },
         1, 0)


         local updateTxt = scheduleWrap(function(ln)
            if #ln > 0 then
               r:set(ln, true)
            end
         end)

         table.insert(jobqueue, function()
            running = running + 1
            command.spawn({
               command = cmd,


               onStdoutLine = updateTxt,
               onStderrLine = updateTxt,
               onExit = function()
                  running = running - 1
                  z.resume(mainTask)
               end,
            })
         end)
      else
         d:setLine(i - 1, pkg:title() .. ": nothing to be done")
      end
   end

   local function spawnJob()
      assert(table.remove(jobqueue, math.random(1, #jobqueue)))()
   end

   while next(jobqueue) or running > 0 do
      while running < actions.maxConcurrentJobs and next(jobqueue) do
         spawnJob()
      end
      z.suspend()
   end

   assert(running == 0, "mainTask finished with jobs still running")
   assert(not next(jobqueue), "mainTask finished with jobs still queued")
end














local function longestInList(list)
   local len = 0
   for _, v in ipairs(list) do
      local itemLen = #v
      if itemLen > len then
         len = itemLen
      end
   end
   return len
end

local function applyPadding(s, len)
   if #s > titleWidth then
      s = s:sub(1, 35)
   end
   return (" "):rep(len - #s) .. s .. " "
end

local function showTitles(d, loaded)
   local lines = {}
   local titles = vim.tbl_map(function(p) return p:title() end, loaded)
   local longest = longestInList(titles)
   for i, title in ipairs(titles) do
      lines[i] = applyPadding(title, longest + 1)
   end
   d:setLines(lines):fitText(nvim.ui().width - 20, 14):center()
end

actions.update = createDialog(function(d)
   local loaded = chooseAndLoadSet(d)
   showTitles(d, loaded)
   runCmdForEachPkg(d, Spec.updateCmd, loaded)
   waitForKey(d, "<cr>")
   d:close()
end)

actions.install = createDialog(function(d)
   local loaded = chooseAndLoadSet(d)
   showTitles(d, loaded)
   runCmdForEachPkg(d, Spec.installCmd, loaded)
   waitForKey(d, "<cr>")
   d:close()
end)

return actions