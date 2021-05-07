


local uv = vim.loop

local SpawnOptions = {}











local function lineReader(linecb)
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
   assert(opts, "expected a table")
   local handle
   local stdout = opts.onStdoutLine and uv.new_pipe(false)
   local stderr = opts.onStderrLine and uv.new_pipe(false)

   local closed = false

   local timeoutTimer = uv.new_timer()
   local function closer(code, signal)
      if closed then return end
      closed = true

      handle:close()
      if stdout then stdout:read_stop(); stdout:close() end
      if stderr then stderr:read_stop(); stderr:close() end
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

   if stdout then stdout:read_start(lineReader(opts.onStdoutLine)) end
   if stderr then stderr:read_start(lineReader(opts.onStderrLine)) end

   timeoutTimer:start(opts.timeout or 30e3, 0, closer)
   return handle
end

return {
   SpawnOptions = SpawnOptions,
   spawn = spawn,
}