
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

local function reader(linecb: function(string)): function(string, string)
	linecb = linecb or function() end
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
	local handle: uv.Handle
	local stdout <const>, stderr <const> = uv.new_pipe(false), uv.new_pipe(false)
	local closed = false

	local timeoutTimer <const> = uv.new_timer()
	local function closer(code: integer, signal: integer)
		if closed then return end
		closed = true

		handle:close()
		stdout:read_stop() stdout:close()
		stderr:read_stop() stderr:close()
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
		stdio = { nil, stdout, stderr }
	}, closer)) as uv.Handle

	stdout:read_start(reader(opts.onStdoutLine))
	stderr:read_start(reader(opts.onStderrLine))

	timeoutTimer:start(opts.timeout or 30e3, 0, closer)
	return handle
end

return {
	SpawnOptions = SpawnOptions,
	spawn = spawn,
}
