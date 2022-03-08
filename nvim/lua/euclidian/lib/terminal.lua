local nvim = require("euclidian.lib.nvim")

local Terminal = {OpenOpts = {}, }



























local function copyOpts(o)
   return {
      [vim.type_idx] = vim.types.dictionary,

      clear_env = o.clearEnv,
      cwd = o.cwd,
      detach = o.detach,
      env = o.env,
      on_exit = o.onExit,
      on_stdout = o.onStdout,
      on_stderr = o.onStderr,
      overlapped = o.overlapped,
      rpc = o.rpc,
      stdout_buffered = o.stdoutBuffered,
      stderr_buffered = o.stderrBuffered,
      stdin = o.stdin,
   }
end

local termopen = vim.fn.termopen

local function ensureOpen(t)
   if t.buf:isValid() and t.buf:getOption("buftype") == "terminal" then
      return
   end
   if not t.buf:isValid() then
      t.buf = nvim.createBuf(false, true)
   end
   if not t.channel or t.channel < 0 then
      t.buf:call(function()
         t.channel = termopen(t.cmd, copyOpts(t.opts))
      end)
   end
end

Terminal.ensureOpen = ensureOpen

local function create(
   cmd,
   opts,
   buf)

   if not buf then
      buf = nvim.createBuf(false, true)
   end
   return setmetatable({
      buf = buf,
      cmd = cmd,
      opts = opts,
   }, { __index = Terminal })
end

local function open(
   cmd,
   opts,
   buf)

   local term = create(cmd, opts, buf)
   ensureOpen(term)
   return term
end

local terminal = {
   Terminal = Terminal,
   create = create,
   open = open,
}

local jobstop = vim.fn.jobstop

function Terminal:close()
   if self.buf:isValid() then
      self.buf:delete({ force = true })
   end
   jobstop(self.channel)
end

function Terminal:send(s)
   if not self.buf:isValid() then
      return false
   end
   nvim.api.chanSend(self.channel, s)
   return true
end

return terminal