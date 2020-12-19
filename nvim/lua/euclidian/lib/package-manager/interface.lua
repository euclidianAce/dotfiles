
local Package = require("euclidian.lib.package-manager.Package")
local cmd = require("euclidian.lib.package-manager.cmd")
local dialog = require("euclidian.lib.package-manager.dialog")
local ev = require("euclidian.lib.ev")
local installer = require("euclidian.lib.package-manager.installer")
local set = require("euclidian.lib.package-manager.set")
local window = require("euclidian.lib.window")

local Dialog = dialog.Dialog
local a = vim.api

local interface = {}
local currentDialog

local function stateMachine(initialState, states)
   local currentState = initialState
   repeat       currentState = states[currentState]()
   until not (currentState and states[currentState])
end

local function startDialog(f)
   currentDialog = coroutine.create(function()
      local d = dialog.new()
      f(d)
      d:close()
      currentDialog = nil
   end)
   coroutine.resume(currentDialog)
end

local function getResult()
   return coroutine.yield()
end


local function choice(d, exclude)
   local excludeSet = {}
   for i, v in ipairs(exclude or {}) do
      excludeSet[v] = true
   end
   local row
   repeat
      coroutine.yield()
      row = d:getCursor()
   until not excludeSet[row]
   return d:getLine(row)
end

local checkKey = "c"
local checkStr = "[%s] %s"
local function checklist(d, title, options)
   local titleLen = #title
   local txt = vim.tbl_map(function(s)
      return "[ ] " .. s
   end, options)
   local function setTxt()
      local t = {}
      for _, v in ipairs(title) do
         table.insert(t, v)
      end
      for _, v in ipairs(txt) do
         table.insert(t, v)
      end
      d:setTxt(t)
   end
   setTxt()
   d:addKeymap("n", checkKey, "select")
   local res = getResult()
   while res == "select" do
      local idx = d:getCursor() - titleLen
      if idx > 0 then
         local checked, opt = txt[idx]:match("^%[(.)%] (.*)$")
         txt[idx] = checkStr:format(checked == "*" and " " or "*", opt)
         setTxt()
      end
      res = getResult()
   end
   d:delKeymap("n", checkKey)
   if res == "next" then
      local ret = {}
      for i, ln in ipairs(txt) do
         if ln:match("^%[%*%]") then
            table.insert(ret, i)
         end
      end
      return ret
   end
   return res
end

local function getTitle(p)
   if p.kind == "git" then
      if p.branch then
         return p.repo .. " (branch: " .. p.branch .. ")"
      end
      return p.repo
   elseif p.kind == "local" then
      return p.path
   end
end

function interface.addPackage()
   startDialog(function(dialog)
      dialog:setWin({ row = 5, col = 5, wid = 50, hei = 30 })
      local p = {}

      local txt = {}
      local selectedSet
      local selectedName

      dialog:addKeymap("n", "<cr>", "next")
      stateMachine("set", {
         set = function()
            local sets = set.list()
            table.insert(sets, 1, "Choose a set to add the package to:")
            dialog:setTxt(sets)
            coroutine.yield()
            local row = dialog:getCursor()
            selectedName = dialog:getLine(row)
            selectedSet = set.load(selectedName)
            return "kind"
         end,
         kind = function()
            for kind in pairs(Package.kinds) do
               table.insert(txt, kind)
            end
            table.sort(txt)
            dialog:setTxt(txt)

            coroutine.yield()
            local row = dialog:getCursor()

            p.kind = dialog:getLine(row)
            return "name"
         end,
         name = function()




            local key
            if p.kind == "git" then
               txt = { "Repo name:", "" }
               key = "repo"
            elseif p.kind == "local" then
               txt = { "File path:", "" }
               key = "path"
            end

            dialog:setTxt(txt):
            setCursor(2, 0):
            setBufOpt("modifiable", true):
            addKeymap("i", "<cr>", "next")
            a.nvim_command("startinsert")

            local res = getResult()
            dialog:delKeymap("i", "<cr>")
            if res == "back" then
               return "kind"
            end
            local name = dialog:getLine(2)
            if #name > 0 then
               (p)[key] = name
               a.nvim_feedkeys("", "i", true)
               dialog:setBufOpt("modifiable", false)
               return "dependents"
            end
            return "name"
         end,
         dependents = function()
            dialog:setTxt({
               ("Do any packages depend on '%s'?"):format(getTitle(p)),
               "Yes", "No",
            })
            dialog:setCursor(3, 0)
            local res = choice(dialog)
            if res == "Yes" then
               local opts = {}
               for _, p in ipairs(selectedSet) do
                  table.insert(opts, getTitle(p))
               end

               local deps = checklist(dialog, {
                  ("Select packages that are dependent on '%s' (from %s):"):format(getTitle(p), selectedName),
               }, opts)
               if type(deps) == "table" and #deps > 0 then
                  p.dependents = {}
                  for _, idx in ipairs(deps) do
                     table.insert(p.dependents, selectedSet[idx])
                  end
               end
            end
            return "dependencies"
         end,
         dependencies = function()
            dialog:setTxt({
               ("Does '%s' depend on any other packages?"):format(getTitle(p)),
               "Yes", "No",
            }):setCursor(3, 0)
            local res = choice(dialog)
            if res == "Yes" then
               local opts = {}
               for _, p in ipairs(selectedSet) do
                  table.insert(opts, getTitle(p))
               end
               local deps = checklist(dialog, {
                  ("Select packages that '%s' depends on (from %s):"):format(getTitle(p), selectedName),
               }, opts)
               if type(deps) == "table" and #deps > 0 then
                  for _, idx in ipairs(deps) do
                     if not selectedSet[idx].dependents then
                        selectedSet[idx].dependents = {}
                     end
                     table.insert(selectedSet[idx].dependents, p)
                  end
               end
            end
            return "done"
         end,
         done = function()
            dialog:setTxt({ ("Package '%s' Added to set %s"):format(getTitle(p), selectedName) })
            table.insert(selectedSet, p)
            set.save(selectedName, selectedSet)
            coroutine.yield()
            return
         end,
      })
   end)
end

local function displaySet(setName)
   local chosenSet = set.load(setName)

   table.sort(
chosenSet,
function(p1, p2)
      return getTitle(p1) < getTitle(p2)
   end)


   local txt = {}
   local function insertPkg(p)
      table.insert(txt, getTitle(p))
      if p.dependents then
         table.insert(txt, "   Dependency for:")
         for i, dep in ipairs(p.dependents) do
            table.insert(txt, "      " .. getTitle(dep))
         end
      end
   end
   for _, p in ipairs(chosenSet) do
      insertPkg(p)
   end

   return txt
end

local UI = {}




local function getUi()
   return a.nvim_list_uis()[1]
end

function interface.viewSets()
   local ui = getUi()
   startDialog(function(dialog)

      dialog:setWin({
         row = 3, col = 3,
         wid = ui.width - 6, hei = ui.height - 6,
      })

      dialog:addKeymap("n", "<cr>", "next")
      dialog:addKeymap("n", "<bs>", "back")

      local setMenu = vim.tbl_map(function(s)
         return "   " .. s
      end, set.list())
      if #setMenu == 0 then
         dialog:setTxt({ "No sets found" })
         return
      end
      table.insert(setMenu, 1, "Sets:")
      local function displayMenu()
         dialog:setTxt(setMenu)
      end

      stateMachine("main", {
         main = function()
            displayMenu()
            local res = getResult()
            if res == "back" then
               return nil
            elseif res == "next" then
               local row = dialog:getCursor()
               if row > 1 then
                  local setName = dialog:getLine(row)
                  dialog:setTxt(displaySet(setName:match("^%s+(.+)$")))
                  return "submenu"
               end
            end
         end,
         submenu = function()
            local res = getResult()
            if res == "back" then
               return "main"
            end
            return "submenu"
         end,
      })
   end)
end

function interface.installSet(set)
   local ui = getUi()
   local d = dialog.new()
   d:setWin({
      row = 3, col = 3,
      wid = ui.width - 6, hei = ui.height - 6,
   })
   local maxConcurrent = 4
   local currentRunning = 0
   local queue = {}
   for i, p in ipairs(set) do
      queue[i] = function()
         ev.worker(function()
            installer.installPackage(p)
         end)
      end
   end
   cmd.wrapAsync(100, function()
      ev.worker(function()
         while #queue > 0 do
            ev.waitUntil(function()
               return currentRunning < maxConcurrent
            end)
            local t = table.remove(queue)
            t()
            currentRunning = currentRunning + 1
         end
      end)








      for name, kind, data in ev.poll do

      end
   end)
end

function interface.advanceDialog(data)
   assert(coroutine.resume(currentDialog, data))
end

return interface
