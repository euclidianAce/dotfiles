local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table
local uv = vim.loop
local z = require("euclidian.lib.async.zig")

local function chunksToLines(chunks)
   local acc = {}
   local lastChunk
   for _, chunk in ipairs(chunks) do
      local lastIdx
      for ln, n in chunk:gmatch("(.-)\n()") do
         if lastChunk then
            table.insert(acc, lastChunk .. ln)
            lastChunk = nil
         else
            table.insert(acc, ln)
         end
         lastIdx = n
      end
      if lastIdx < #chunk then
         lastChunk = chunk:sub(lastIdx, -1)
      end
   end
   if lastChunk then
      table.insert(acc, lastChunk)
   end
   return acc
end

local SpawnOptions = {}





local Result = {}





local function spawn(opts)
   local handle
   local stdoutData = {}
   local stderrData = {}
   local stdout, stderr = uv.new_pipe(false), uv.new_pipe(false)
   local closed = false
   local exitCode, exitSignal
   local timeoutTimer = uv.new_timer()
   local function closer(code, signal)
      if closed then return end
      closed = true

      handle:close()
      stdout:read_stop(); stdout:close()
      stderr:read_stop(); stderr:close()
      timeoutTimer:stop(); timeoutTimer:close()

      exitCode, exitSignal = code, signal
   end
   local cmdName = opts.command[1]
   local args = { unpack(opts.command, 2) }
   handle = uv.spawn(cmdName, {
      args = args,
      cwd = opts.cwd,
      stdio = { nil, stdout, stderr },
   }, closer)
   stdout:read_start(function(err, data)
      assert(not err, err)
      table.insert(stdoutData, data)
   end)
   stderr:read_start(function(err, data)
      assert(not err, err)
      table.insert(stderrData, data)
   end)

   timeoutTimer:start(opts.timeout or 30e3, 0, closer)

   while not closed do
      z.suspend()
   end
   return {
      stdout = chunksToLines(stdoutData),
      stderr = chunksToLines(stderrData),
      exit = exitCode,
      signal = exitSignal,
   }
end

return {
   Result = Result,

   spawn = spawn,
}