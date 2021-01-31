
local tree = require("euclidian.lib.package-manager.tree")
local ev = require("euclidian.lib.ev")
local packagespec = require("euclidian.lib.package-manager.packagespec")
local uv = vim.loop

local Spec = packagespec.Spec

local cmdCallbacks = {}






local cmdOpts = {}







local function runCmd(o)
   assert(o)
   local cbs = o.on or {}

   local cmdName = o.command[1]
   local args = {}
   for i = 2, #o.command do
      args[i - 1] = o.command[i]
   end

   local stdout = uv.new_pipe(false)
   local stderr = uv.new_pipe(false)

   local handle
   local timeoutTimer = uv.new_timer()
   local closed = false
   local function closer()
      if closed then return end
      closed = true

      handle:close()
      stdout:close(); stdout:read_stop()
      stderr:close(); stderr:read_stop()
      timeoutTimer:stop(); timeoutTimer:close()

      if cbs.close then
         cbs.close()
      end
   end

   handle = assert(uv.spawn(cmdName, {
      cwd = o.cwd,
      args = args,
      stdio = { nil, stdout, stderr },
   }, closer))

   stdout:read_start(function(err, data)
      assert(not err, err)
      if data and cbs.stdout then
         cbs.stdout(data)
      end
   end)
   stderr:read_start(function(err, data)
      assert(not err, err)
      if data and cbs.stderr then
         cbs.stderr(data)
      end
   end)

   timeoutTimer:start(o.timeout or 30000, 0, closer)

   if cbs.start then
      cbs.start()
   end
end

local function eventedCmd(opts)
   local thread = opts.thread or coroutine.running()
   local closed = false
   local command = opts.command
   local optsOn = opts.on or {}
   runCmd({
      command = command,
      cwd = opts.cwd,
      on = {
         stdout = function(data)
            ev.queue(thread, { kind = "stdout", data })
            if optsOn.stdout then
               vim.schedule(function()
                  optsOn.stdout(data)
               end)
            end
         end,
         stderr = function(data)
            ev.queue(thread, { kind = "stderr", data })
            if optsOn.stderr then
               vim.schedule(function()
                  optsOn.stderr(data)
               end)
            end
         end,
         start = function()
            ev.queue(thread, { kind = "start", command })
            if optsOn.start then
               vim.schedule(optsOn.start)
            end
         end,
         close = function()
            ev.queue(thread, { kind = "finish", command })
            closed = true
            if optsOn.close then
               vim.schedule(optsOn.close)
            end
         end,
      },
   })

   ev.anchor(function()
      return not closed
   end)
end

local git = {}

function git.clone(p)
   assert(p.kind == "git", "Attempt to git.clone a non git package")
   eventedCmd({
      command = { "git", "clone", "https://github.com/" .. p.repo, p.repo:match("[^/]+$") },
   })
end

function git.pull(p)
   assert(p.kind == "git", "Attempt to git.pull a non git package")
   eventedCmd({
      command = { "git", "pull" },
      cwd = tree.neovim .. "/" .. p.repo:match("[^/]+$"),
   })
end


local luarocks = {}
function luarocks.list()
end

function luarocks.install()
end

function luarocks.remove()
end

return {
   run = runCmd,
   runEvented = eventedCmd,
   git = git,
   luarocks = luarocks,
}
