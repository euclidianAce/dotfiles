local command = require("euclidian.lib.command")
local configure = require("euclidian.plug.package-manager.configure")
local dialog = require("euclidian.lib.dialog")
local input = require("euclidian.lib.input")
local menu = require("euclidian.lib.menu")
local nvim = require("euclidian.lib.nvim")
local packagespec = require("euclidian.plug.package-manager.packagespec")
local report = require("euclidian.plug.package-manager.report")
local set = require("euclidian.plug.package-manager.set")
local tu = require("euclidian.lib.textutils")

local z = require("euclidian.lib.azync")

local NilFrame = {}
local Action = {}

local actions = {
   maxConcurrentJobs = 2,

   view = nil,
   update = nil,
   install = nil,
   add = nil,
   remove = nil,
   configure = nil,
   newSet = nil,
}

local Spec = packagespec.Spec
local Dialog = dialog.Dialog
local function setCmp(a, b)
   return a:title() < b:title()
end

local function defaultDialog()
   return dialog.new({
      centered = true,
      wid = .75,
      hei = .3,
      interactive = true,
      ephemeral = true,
   })
end

local function createDialog(fn)
   return function()
      local d = defaultDialog()
      d:ensureBuf()
      d:ensureWin():setOption("wrap", false)
      return z.async(fn, d)
   end
end

local function createAccordionForEachSet(cb)
   local items = {}
   for _, s in ipairs(set.list()) do
      local pkgs = set.load(s)
      table.sort(pkgs, setCmp)
      table.insert(items, (cb(s, pkgs)))
   end

   local world = set.getWorld()
   table.sort(world, setCmp)
   table.insert(items, (cb("@World", world)))

   return menu.new.accordion(items)
end

actions.view = function()
   local m = createAccordionForEachSet(function(title, pkgs)
      local names = {}
      for i, spec in ipairs(pkgs) do
         names[i] = { spec:title() }
      end
      return { title, names }
   end)
   return z.async(m, defaultDialog())
end

local function chooseAndLoadSet(d)
   local sets = set.list()
   table.insert(sets, "@World")
   table.sort(sets)

   local loaded, name
   local items = {}
   for i, v in ipairs(sets) do
      items[i] = { v, function()
         loaded = set.load(v)
         name = v
      end, }
   end

   menu.new.accordion(items)(d, { persist = true })
   if not loaded then

      coroutine.yield()
   end
   return loaded, name
end

local function prompt(d, promptText)
   local f = z.currentFrame()
   local val
   d:setPrompt(promptText, function(s)
      val = s
      d:unsetPrompt()
      vim.schedule(function()
         z.resume(f)
      end)
   end)
   z.suspend()
   return val
end














local function checklist(d, pre, opts)
   local items = { pre }
   for i, v in ipairs(opts) do
      items[i + 1] = { v, false }
   end
   menu.new.checklist(items)(d)
   local selected = {}
   for i = 2, #items do
      if (items[i])[2] then
         table.insert(selected, i - 1)
      end
   end
   return selected
end

do
   local PackageAdder = {}
   local function getPkgNames(s)
      local pkgNames = {}
      for i, v in ipairs(s) do
         pkgNames[i] = v:title()
      end
      return pkgNames
   end

   local function askForDependents(d, s, p)
      if #s == 0 then return end
      local deps = checklist(d, "Dependents:", getPkgNames(s))
      for _, idx in ipairs(deps) do
         table.insert(p.dependents, s[idx])
      end
   end

   local function askForDependencies(d, s, p)
      if #s == 0 then return end
      local deps = checklist(d, "Dependencies:", getPkgNames(s))
      for _, idx in ipairs(deps) do
         if not s[idx].dependents then
            s[idx].dependents = {}
         end
         table.insert(s[idx].dependents, p)
      end
   end

   local addVimPlugPackage = function(_d, _s)
      print("Vim Plug Package: not yet implemented")
   end

   local addPackerPackage = function(_d, _s)
      print("Packer Package: not yet implemented")
   end

   local addGitPackage = function(d, s)
      d:setLines({})
      local remote = prompt(d, "Remote: ")
      local pkgNames = {}
      for i, v in ipairs(s) do
         pkgNames[i] = v:title()
      end
      local p = {
         kind = "git",
         dependents = {},
         remote = remote,
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
   local function addLuaRock(_d, _s)
      print("TODO: add lua rock :D")
   end

   actions.add = createDialog(function(d)
      local loaded, name = chooseAndLoadSet(d)

      set.save("." .. name .. "__bak", loaded)

      local function wrap(fn)
         return function() fn(d, loaded) end
      end

      menu.new.accordion({
         "Add new package from:",
         { "Git", wrap(addGitPackage) },
         { "Local directory", wrap(addLocalPackage) },
         { "Vim-Plug expression", wrap(addVimPlugPackage) },
         { "Packer expression", wrap(addPackerPackage) },
         { "Lua rock", wrap(addLuaRock) },
      })(d, { persist = true })

      set.save(name, loaded)
      d:close()
   end)
end



















local function runCmdForEachPkg(d, getcmd, loaded)
   local mainTask

   local jobqueue = {}
   local running = 0

   local menuItems = {}
   local acc = menu.new.accordion(menuItems)

   local redraw = vim.schedule_wrap(function()
      if d:win():isValid() and acc.redraw then
         acc.redraw()
      end
   end)

   for i, pkg in ipairs(loaded) do
      local cmd = getcmd(pkg)
      local title = pkg:title()
      local StreamOutputItem = {}
      local item = { pkg:title() }
      menuItems[i] = item
      if cmd then
         local out = {}
         local err = {}
         item[2] = { { "stdout", out }, { "stderr", err } }

         table.insert(jobqueue, function()
            running = running + 1
            item[1] = title .. " : Working..."
            command.spawn({
               command = cmd,
               onStdoutLine = function(ln)
                  table.insert(out, ln)
                  redraw()
               end,
               onStderrLine = function(ln)
                  table.insert(err, ln)
                  redraw()
               end,
               onExit = function(code)
                  running = running - 1
                  if code == 0 then
                     item[1] = title .. " : Done!"
                  else
                     item[1] = title .. " : Error! (" .. tostring(code) .. ")"
                  end
                  redraw()
                  z.resume(mainTask)
               end,
            })
         end)
      else
         item[1] = item[1] .. " : Nothing to be done"
      end
   end

   local function spawnJob()
      assert(
      table.remove(jobqueue, math.random(1, #jobqueue)),
      "tried to spawn a job with none in the queue")()

   end

   return z.async(function()
      mainTask = z.currentFrame()
      z.async(acc, d)
      while next(jobqueue) or running > 0 do
         while running < actions.maxConcurrentJobs and next(jobqueue) do
            spawnJob()
         end
         z.suspend()
      end
      assert(running == 0, "mainTask finished with jobs still running")
      assert(not next(jobqueue), "mainTask finished with jobs still queued")
   end)
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

local function showTitles(d, loaded, rightAlign)
   local lines = {}
   local titles = vim.tbl_map(function(p) return p:title() end, loaded)
   local longest = longestInList(titles)
   for i, title in ipairs(titles) do
      local limited = tu.limit(title, 35, true)
      if rightAlign then
         limited = tu.rightAlign(limited, longest + 1)
      end
      lines[i] = limited .. " "
   end
   d:setLines(lines):fitText(nvim.ui().width - 20, 14):center()
end

actions.remove = createDialog(function(d)
   local loaded, name = chooseAndLoadSet(d)
   table.sort(loaded)

   showTitles(d, loaded)


   input.waitForKey(d:buf(), "n", "<cr>")
   local ln = d:getCursor()
   local selected = loaded[ln]

   if selected.dependents and next(selected.dependents) then
      local lns = { "Selected package: " .. selected:title() .. " is a dependency for:" }
      for _, p in ipairs(selected.dependents) do
         table.insert(lns, "   " .. assert(type(p) == "table" and p):title())
      end
      d:setLines(lns)
      input.waitForKey(d:buf(), "n", "<cr>")
      d:close()
      return
   end

   table.remove(loaded, ln)
   local ok, err = set.save(name, loaded)

   if ok then
      d:setLines({ "Removed package: " .. selected:title() }):fitText():center()
   else
      d:setLines({
         "Unable to remove package: " .. selected:title(),
         err,
      }):fitText():center()
   end

   input.waitForKey(d:buf(), "n", "<cr>")
   d:close()
end)

actions.update = createDialog(function(d)
   local loaded = chooseAndLoadSet(d)
   if not loaded then return end
   z.await(runCmdForEachPkg(d, Spec.updateCmd, loaded))

end)

actions.install = createDialog(function(d)
   local loaded = chooseAndLoadSet(d)
   if not loaded then return end
   z.await(runCmdForEachPkg(d, Spec.installCmd, loaded))
end)

actions.newSet = createDialog(function(d)
   local name
   local setSet = {}
   for _, s in ipairs(set.list()) do
      setSet[s] = true
   end

   local frame = z.currentFrame()
   d:setPrompt(
   "New Set Name: ",
   function(s)
      if not set.isValidName(s) then
         d:appendLines({ ("%q is not a valid set name: invalid characters"):format(s) })
         return
      elseif setSet[name] then
         d:appendLines({ ("%q is not a valid set name: set already exists"):format(s) })
         return
      else
         name = s
         z.resume(frame)
      end
   end)

   z.suspend()
   d:unsetPrompt()
   local ok, err = set.save(name, {})
   if ok then
      vim.notify("Saved new set: " .. name)
   else
      vim.notify("Unable to save new set " .. name .. ": " .. err, vim.log.levels.ERROR)
   end
   d:close()
end)

actions.configure = createDialog(function(d)
   local cfg, err = configure.load()
   if err then

      d:setLines({ "There was an error loading your config:", err })
      input.waitForKey(d:buf(), "n", "<cr>", "<bs>")
      d:close()
      return
   end

   local addLine
   local addHandler
   local getHandler
   local show
   local clear
   do

      local handlers = {}
      local txt = {}

      addLine = function(fmt, ...)
         tu.insertFormatted(txt, fmt, ...)
      end
      addHandler = function(fn)
         handlers[#txt] = fn
      end
      getHandler = function(ln)
         for i = ln, #txt do
            if handlers[i] then
               return handlers[i]
            end
         end
      end
      show = function()
         d:setLines(txt):fitText(35, 17):center()
      end
      clear = function()
         txt = {}
         handlers = {}
         d:setLines({})
      end
   end

   local function updateUintOptHandler(prefix, field)
      return function()
         clear()
         local result = prompt(d, prefix)
         local numResult = tonumber(result)
         if not numResult then
            print("expected a number")
            return
         end
         if numResult <= 0 or math.floor(numResult) ~= numResult then
            print("expected a positive integer")
            return
         end;
         (cfg)[field] = numResult
      end
   end










   local function appendToStringListHandler(prefix, field)
      return function()
         clear()
         local result = prompt(d, prefix)
         if result ~= "" then
            table.insert((cfg)[field], result)
         end
      end
   end

   local function fillDialog()
      clear()
      addLine("Enabled Sets:")
      table.sort(cfg.enable)
      for _, s in ipairs(cfg.enable) do
         addLine("   %s", s)
      end
      addHandler(appendToStringListHandler("Add Set: ", "enable"))

      addLine("Max Concurrent Jobs: %d", cfg.maxConcurrentJobs)
      addHandler(updateUintOptHandler("Max Concurrent Jobs: ", "maxConcurrentJobs"))
   end

   fillDialog()
   show()

   while input.waitForKey(d:buf(), "n", "<cr>", "<bs>") == "<cr>" do
      local ln, col = d:getCursor()
      local handler = getHandler(ln)
      if handler then
         handler()
         fillDialog()
         show()
         d:setCursor(ln, col)
      end
   end

   configure.save(cfg)
   report.msg("Configuration saved!")
   d:close()
end)

return actions