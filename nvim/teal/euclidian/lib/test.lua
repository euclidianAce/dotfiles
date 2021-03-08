
local pmode = libreq"printmode"
local print = vim.schedule_wrap(pmode.printfn"buffer")

local promise = req"euclidian.lib.promise"
local a = promise.a
local uv = vim.loop


local function runCmd(cmd, timeout)
	print("cmd: ", cmd)
	local cmdName = cmd[1]
	local args = {}
	for i = 2, #cmd do
		args[i-1] = cmd[i]
	end

	return promise.new(function(res, rej)
		local stdout = uv.new_pipe(false)
		local stderr = uv.new_pipe(false)

		local handle
		local timeoutTimer = uv.new_timer()
		local closed = false
		local stdoutData = {}
		local stderrData = {}

		local function closer()
			if closed then return end
			closed = true

			handle:close()
			stdout:close() stdout:read_stop()
			stderr:close() stderr:read_stop()
			timeoutTimer:stop() timeoutTimer:close()

			-- TODO: this could be done better
			local stdoutLines = vim.split(table.concat(stdoutData), "\n", true)
			local stderrLines = vim.split(table.concat(stderrData), "\n", true)
			res({stdoutLines, stderrLines})
		end

		handle = assert(uv.spawn(cmdName, {
			args = args,
			stdio = { nil, stdout, stderr },
		}, closer))

		stdout:read_start(function(err, data)
			assert(not err, err)
			if data then
				table.insert(stdoutData, data)
			end
		end)
		stderr:read_start(function(err, data)
			assert(not err, err)
			if data then
				table.insert(stderrData, data)
			end
		end)

		timeoutTimer:start(timeout or 30e3, 0, closer)
	end)
end

runCmd({"echo", "hi"})
	:andThen(function(lines)
		print("stdout: ", lines[1])
		print("stderr: ", lines[2])
	end)

