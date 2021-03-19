local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table
local command = require("euclidian.lib.command")
local dialog = require("euclidian.lib.dialog")
local packagespec = require("euclidian.lib.package-manager.packagespec")
local set = require("euclidian.lib.package-manager.set")
local z = require("euclidian.lib.async.zig")

local actions = {
   listSets = nil,
   update = nil,
   install = nil,
}

local Spec = packagespec.Spec
local Dialog = dialog.Dialog
local function setCmp(a, b)
   return a:title() < b:title()
end

local function createDialog(fn)
   return function()
      local d = dialog.centered(35, 17)
      return z.async(fn, d)
   end
end

local function waitForKey(d, ...)
   local keys = { ... }
   local function delKeymaps()
      for _, key in ipairs(keys) do
         d:delKeymap("n", key)
      end
   end
   local pressed
   z.suspend(function(me)
      for _, key in ipairs(keys) do
         d:addKeymap("n", key, function()
            pressed = key
            delKeymaps()
            z.resume(me)
         end, { noremap = true, silent = true })
      end
   end)
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

   return set.load(d:getCurrentLine())
end

local maxConcurrent = 2
actions.update = createDialog(function(d)
   local loaded = chooseAndLoadSet(d)

   local lines = {}
   for i, pkg in ipairs(loaded) do
      lines[i] = " " .. pkg:title() .. " "
   end
   d:setLines(lines):fitText()

   local main = z.currentFrame()

   local jobsleft = #loaded
   local running = 0

   local onCmdExit = vim.schedule_wrap(function()
      jobsleft = jobsleft - 1
      running = running - 1
      z.resume(main)
   end)

   local jobqueue = {}
   for i, pkg in ipairs(loaded) do
      if pkg.kind == "git" then
         local updateTxt = vim.schedule_wrap(function(ln)


            d:setLine(i - 1, " " .. pkg:title() .. ": " .. ln:sub(1, 20) .. " "):
            fitText():
            center()
         end)

         table.insert(jobqueue, function()
            running = running + 1
            command.spawn({
               command = { "git", "pull" },
               cwd = pkg:location(),
               onStdoutLine = updateTxt,
               onStderrLine = updateTxt,
               onExit = onCmdExit,
            })
         end)
      else
         jobsleft = jobsleft - 1
         d:setLine(i - 1, pkg:title() .. ": not a git package :D")
      end
   end

   while jobsleft > 0 do
      while running < maxConcurrent and #jobqueue > 0 do
         table.remove(jobqueue, math.random(1, #jobqueue))()
      end
      z.suspend()
   end

   waitForKey(d, "<cr>")
   d:close()
end)

actions.install = createDialog(function(d)
   local loaded = chooseAndLoadSet(d)

   local lines = {}
   for i, pkg in ipairs(loaded) do
      lines[i] = " " .. pkg:title() .. " "
   end
   d:setLines(lines):fitText()

   local main = z.currentFrame()

   local jobsleft = #loaded
   local running = 0

   local onCmdExit = vim.schedule_wrap(function()
      jobsleft = jobsleft - 1
      running = running - 1
      z.resume(main)
   end)

   local jobqueue = {}
   for i, pkg in ipairs(loaded) do
      if pkg:isInstalled() then
         if pkg.kind == "git" then
            local updateTxt = vim.schedule_wrap(function(ln)


               d:setLine(i - 1, " " .. pkg:title() .. ": " .. ln:sub(1, 20) .. " "):
               fitText():
               center()
            end)

            table.insert(jobqueue, function()
               running = running + 1
               command.spawn({
                  command = { "git", "clone", "https://github.com/" .. pkg.repo, pkg:location() },
                  onStdoutLine = updateTxt,
                  onStderrLine = updateTxt,
                  onExit = onCmdExit,
               })
            end)
         else
            jobsleft = jobsleft - 1
            d:setLine(i - 1, pkg:title() .. ": not a git package :D")
         end
      else
         jobsleft = jobsleft - 1
         d:setLine(i - 1, pkg:title() .. ": already installed")
      end
   end

   while jobsleft > 0 do
      while running < maxConcurrent and #jobqueue > 0 do
         table.remove(jobqueue, math.random(1, #jobqueue))()
      end
      z.suspend()
   end

   waitForKey(d, "<cr>")
   d:close()
end)

return actions