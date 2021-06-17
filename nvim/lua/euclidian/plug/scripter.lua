local a = vim.api
local dialog = require("euclidian.lib.dialog")
local fs = require("euclidian.lib.fs")
local notification = require("euclidian.lib.notification")
local nvim = require("euclidian.lib.nvim")
local quick = require("euclidian.lib.dialog.quick")
local z = require("euclidian.lib.async.zig")



local stdpath = vim.fn.stdpath

local scripter = {Opts = {}, }







local dir = stdpath("config") .. "/.scripter"
local function scriptPath(name)
   return dir .. "/" .. name
end

local currentScript, currentScriptChanged
local openEditor, openBrowser

local mainDialog = dialog.new({
   wid = 75, hei = 30,
   centered = true,
   interactive = true,
   notMinimal = true,
   hidden = true,
})
mainDialog:setModifiable(true)

local function execBuffer(b)
   local lines = b:getLines(0, -1, false);
   local txt = table.concat(lines, "\n")

   local chunk, loaderr = loadstring(txt)
   if not chunk then
      a.nvim_err_writeln(loaderr)
      return
   end
   local ok, err = pcall(chunk)
   if not ok then
      a.nvim_err_writeln(err)
   end
end

local promptOpts = {
   wid = 45, hei = 1,
   centered = true,
   interactive = true,
   ephemeral = true,
}

local function saveBufferToFile(buf, file)
   assert(buf)
   assert(file)
   if not currentScriptChanged then
      return
   end
   local realPath = scriptPath(file)
   local fh, err = io.open(realPath, "w")
   if err then
      notification.create("Could not save script " .. file .. ": " .. tostring(err))
      return
   end
   for _, ln in ipairs(buf:getLines(0, -1, false)) do
      fh:write(ln, "\n")
   end
   fh:close()
   notification.create("Saved script " .. file)
   currentScriptChanged = false
end

local function clearMappings(d)
   for _, map in ipairs(d:buf():getKeymap("n")) do
      d:delKeymap("n", map.lhs)
   end
end

openEditor = function()
   assert(currentScript)
   clearMappings(mainDialog)
   local buf = mainDialog:ensureBuf()
   local win = mainDialog:ensureWin()
   nvim.augroup("ScripterBrowserFloat", {}, true)
   mainDialog:focus()

   local text = {}
   if fs.exists(scriptPath(currentScript)) then
      for ln in io.lines(scriptPath(currentScript)) do
         table.insert(text, ln)
      end
   end
   mainDialog:setLines(text)

   mainDialog:setWinSize(75, 30):center()
   win:setOption("cursorline", false)
   win:setOption("number", true)
   win:setOption("relativenumber", true)

   mainDialog:setModifiable(true)
   buf:setOption("ft", "lua")
   buf:setKeymap(
   "n", "<cr>",
   function() execBuffer(mainDialog:buf()) end,
   { silent = true, noremap = true })

   local save = z.asyncFn(function()
      if not currentScript then
         currentScript = quick.prompt("Save As: ", promptOpts)
      end
      saveBufferToFile(buf, currentScript)
   end)
   buf:setKeymap(
   "n", "<bs>",
   function()
      z.nosuspend(save)
      currentScript = nil
      openBrowser()
   end,
   { silent = true, noremap = true })

   buf:setKeymap(
   "n", "",
   function() mainDialog:hide() end,
   { silent = true, noremap = true })

   buf:setKeymap(
   "n", "<leader>W",
   save,
   { silent = true, noremap = true })

   mainDialog:show()
   buf:attach(false, {
      on_lines = function()
         if currentScript then
            currentScriptChanged = true
         end
         return true
      end,
   })
end


local function getWinVar(win, name)
   local var
   pcall(function()
      var = win:getVar(name)
   end)
   return var
end

openBrowser = function()
   assert(not currentScript)
   local win = mainDialog:ensureWin()
   local buf = mainDialog:ensureBuf()

   mainDialog:setModifiable(false)
   a.nvim_set_current_win(win.id)
   win:setOption("cursorline", true)
   win:setOption("number", false)
   win:setOption("relativenumber", false)
   buf:setOption("ft", "")

   clearMappings(mainDialog)
   local scripts = {}
   for f in fs.ls(dir) do
      table.insert(scripts, f)
   end
   mainDialog:setLines(scripts)
   mainDialog:fitTextPadded(2, 2, 50, 10):center()
   if #scripts == 0 then
      z.async(function()
         if quick.yesOrNo("No scripts found, create new script?") then
            currentScript = quick.prompt("Name: ", promptOpts)
            openEditor()
         else
            mainDialog:close()
         end
      end)
      return
   end
   mainDialog:addKeymap("n", "<bs>", function() mainDialog:close() end, {})
   mainDialog:addKeymap("n", "<cr>", function()
      currentScript = mainDialog:getCurrentLine()
      openEditor()
   end, {})
   mainDialog:addKeymap("n", "dd", z.asyncFn(function()
      local file = mainDialog:getCurrentLine()
      if quick.yesOrNo("Delete " .. file .. "?") then
         os.remove(scriptPath(file))
         openBrowser()
      end
   end), { noremap = true })
   nvim.augroup("ScripterBrowserFloat", {


      { "WinLeave", nil, vim.schedule_wrap(function()
         if not getWinVar(nvim.Window(), "QuickDialog") then
            mainDialog:close()
         end
      end), { buffer = buf.id }, },
   }, true)
end

function scripter.open()
   if currentScript then
      openEditor()
   else
      openBrowser()
   end
end

return setmetatable(scripter, {
   __call = function(_self, opts)
      opts = opts or {}
      if opts.dir then
         dir = opts.dir
      end

      if not fs.exists(dir) then
         fs.mkdirp(dir)
      end

      if opts.open then
         nvim.setKeymap(
         "n", opts.open,
         scripter.open,
         { noremap = true, silent = true })

      end
   end,
})