
local uv <const> = vim.loop
local z <const> = require("euclidian.lib.async.zig")

local function chunksToLines(chunks: {string}): {string}
	local acc = {}
	local lastChunk: string
	for _, chunk in ipairs(chunks) do
		local lastIdx: integer
		for ln, n in chunk:gmatch("(.-)\n()") do
			if lastChunk then
				table.insert(acc, lastChunk .. ln)
				lastChunk = nil
			else
				table.insert(acc, ln)
			end
			lastIdx = n as number
		end
		if lastIdx < #chunk then
			lastChunk =  chunk:sub(lastIdx, -1)
		end
	end
	if lastChunk then
		table.insert(acc, lastChunk)
	end
	return acc
end

local record SpawnOptions
	cwd: string
	command: {string}
	timeout: integer
end

local record Result
	stdout: {string}
	stderr: {string}
	exit: integer
	signal: integer
end
local function spawn(opts: SpawnOptions): Result
	local handle: uv.Handle
	local stdoutData <const> = {}
	local stderrData <const> = {}
	local stdout <const>, stderr <const> = uv.new_pipe(false), uv.new_pipe(false)
	local closed = false
	local exitCode, exitSignal: integer, integer
	local timeoutTimer <const> = uv.new_timer()
	local function closer(code: integer, signal: integer)
		if closed then return end
		closed = true

		handle:close()
		stdout:read_stop() stdout:close()
		stderr:read_stop() stderr:close()
		timeoutTimer:stop() timeoutTimer:close()

		exitCode, exitSignal = code, signal
	end
	local cmdName <const> = opts.command[1]
	local args <const> = { unpack(opts.command, 2) }
	handle = uv.spawn(cmdName, {
		args = args,
		cwd = opts.cwd,
		stdio = { nil, stdout, stderr }
	}, closer) as uv.Handle
	stdout:read_start(function(err: string, data: string)
		assert(not err, err)
		table.insert(stdoutData, data)
	end)
	stderr:read_start(function(err: string, data: string)
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
