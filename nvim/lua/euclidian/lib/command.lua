
local uv = vim.loop

local SpawnOptions = {}











local function reader(linecb)
   linecb = linecb or function() end
   local lastChunk
   return function(err, chunk)
      assert(not err, err)
      local lastIdx
      if chunk then
         for ln, n in chunk:gmatch("(.-)\n()") do
            if lastChunk then
               linecb(lastChunk .. ln)
               lastChunk = nil
            else
               linecb(ln)
            end
            lastIdx = n
         end
         if lastIdx < #chunk then
            lastChunk = chunk:sub(lastIdx, -1)
         else
            lastChunk = nil
         end
      elseif lastChunk then
         linecb(lastChunk)
      end
   end
end

local function spawn(opts)
   local handle
   local stdout, stderr = uv.new_pipe(false), uv.new_pipe(false)
   local closed = false

   local timeoutTimer = uv.new_timer()
   local function closer(code, signal)
      if closed then return end
      closed = true

      handle:close()
      stdout:read_stop(); stdout:close()
      stderr:read_stop(); stderr:close()
      timeoutTimer:stop(); timeoutTimer:close()

      if opts.onExit then
         opts.onExit(code, signal)
      end
   end
   local cmdName = opts.command[1]
   local args = { unpack(opts.command, 2) }

   handle = assert(uv.spawn(cmdName, {
      args = args,
      cwd = opts.cwd,
      stdio = { nil, stdout, stderr },
   }, closer))

   stdout:read_start(reader(opts.onStdoutLine))
   stderr:read_start(reader(opts.onStderrLine))

   timeoutTimer:start(opts.timeout or 30e3, 0, closer)
   return handle
end

return {
   SpawnOptions = SpawnOptions,
   spawn = spawn,
}