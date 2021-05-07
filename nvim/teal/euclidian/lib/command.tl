
-- very simple libuv spawn wrapper with more convenient callbacks

local uv <const> = vim.loop

local record SpawnOptions
	cwd: string
	command: {string}
	timeout: integer

	-- Callbacks for when the process produces data
	-- it is the responsibility of the caller to `schedule_wrap` their api calls
	onStdoutLine: function(string)
	onStderrLine: function(string)
	onExit: function(integer, integer)
end

local function lineReader(linecb: function(string)): function(string, string)
	local lastChunk: string
	return function(err: string, chunk: string)
		assert(not err, err)
		local lastIdx: integer
		if chunk then
			for ln, n in chunk:gmatch("(.-)\n()") do
				if lastChunk then
					linecb(lastChunk .. ln)
					lastChunk = nil
				else
					linecb(ln)
				end
				lastIdx = n as integer
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

local function spawn(opts: SpawnOptions): uv.Handle
	assert(opts, "expected a table")
	local handle: uv.Handle
	local stdout <const> = opts.onStdoutLine and uv.new_pipe(false)
	local stderr <const> = opts.onStderrLine and uv.new_pipe(false)

	local closed = false

	local timeoutTimer <const> = uv.new_timer()
	local function closer(code: integer, signal: integer)
		if closed then return end
		closed = true

		handle:close()
		if stdout then stdout:read_stop() stdout:close() end
		if stderr then stderr:read_stop() stderr:close() end
		timeoutTimer:stop() timeoutTimer:close()

		if opts.onExit then
			opts.onExit(code, signal)
		end
	end
	local cmdName <const> = opts.command[1]
	local args <const> = { unpack(opts.command, 2) }

	handle = assert(uv.spawn(cmdName, {
		args = args,
		cwd = opts.cwd,
		stdio = { nil, stdout, stderr },
	}, closer)) as uv.Handle

	if stdout then stdout:read_start(lineReader(opts.onStdoutLine)) end
	if stderr then stderr:read_start(lineReader(opts.onStderrLine)) end

	timeoutTimer:start(opts.timeout or 30e3, 0, closer)
	return handle
end

return {
	SpawnOptions = SpawnOptions,
	spawn = spawn,
}
