
local uv = vim.loop
local ev = require("euclidian.lib.ev")
local tree = require("euclidian.lib.package-manager.tree")

local CommandOpts = {}




local function reader(t, evName, streamName)
   return function(err, data)
      assert(not err, err)
      if data then
         ev.queueForThread(t, evName, streamName, data)
      end
   end
end







local function runCmd(evName, msTimeout, opts)
   assert(opts)

   local cmdName = opts[1]
   local args = {}
   for i = 2, #opts do
      args[i - 1] = opts[i]
   end


   local stdio = { uv.new_pipe(), uv.new_pipe(), uv.new_pipe() }

   local currentThread = coroutine.running()

   ev.queueForThread(currentThread, evName, "start")
   local timeoutTimer = uv.new_timer()

   local handle
   local closed = false
   local function closer(a, b)
      if closed then          return end
      closed = true
      ev.queueForThread(currentThread, evName, "done")
      handle:close()

      stdio[1]:close()
      stdio[2]:close(); stdio[2]:read_stop()
      stdio[3]:close(); stdio[3]:read_stop()
      timeoutTimer:close(); timeoutTimer:stop()
   end

   handle = uv.spawn(cmdName, {
      cwd = opts.cwd,
      args = args,
      stdio = stdio,
   }, closer)

   stdio[2]:read_start(reader(currentThread, evName, "stdout"))
   stdio[3]:read_start(reader(currentThread, evName, "stderr"))

   timeoutTimer:start(msTimeout, 0, closer)

   ev.worker(function()
      ev.waitUntil(function()
         return closed
      end)
   end)
end

local defaultTimeout = 60000
local luarocks = {}
do
   local function cmd(evKind, ...)
      runCmd(evKind, defaultTimeout, { "luarocks", "--tree", tree.luarocks, "--lua-version=5.1", ... })
   end

   function luarocks.install(evKind, rock)
      cmd(evKind, "install", rock)
   end

   function luarocks.remove(evKind, rock)
      cmd(evKind, "remove", rock)
   end

   function luarocks.list(evKind)
      cmd(evKind, "list")
   end
end

local git = {}
do
   function git.clone(evKind, repo, dest)
      runCmd(evKind, defaultTimeout, { "git", "clone", "https://github.com/" .. repo, dest })
   end

   function git.pull(evKind, dir)
      runCmd(evKind, defaultTimeout, { "git", "pull", cwd = dir })
   end
end

local function wrapAsync(msInterval, f)
   local l = ev.loop(f)
   local t = uv.new_timer()
   t:start(0, msInterval, function()
      if l:isAlive() then
         l:step()
      elseif not t:is_closing() then
         t:stop()
         t:close()
      end
   end)
end

return {
   luarocks = luarocks,
   git = git,
   wrapAsync = wrapAsync,
   runCmd = runCmd,
}
