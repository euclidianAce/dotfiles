local uv = vim.loop

local cwd = vim.fn.getcwd()

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
			lastChunk =  chunk:sub(lastIdx, -1)
		end
	end
	if lastChunk then
		table.insert(acc, lastChunk)
	end
	return acc
end

local function getRetVal(stdoutChunks, stderrChunks, code, signal)
	return {
		stdout = chunksToLines(stdoutChunks),
		stderr = chunksToLines(stderrChunks),
		signal = signal,
		code = code,
	}
end

local function spawn(closeCb, ...)
	local handle
	local stdoutData = {}
	local stderrData = {}
	local stdout, stderr = uv.new_pipe(false), uv.new_pipe(false)
	local closed = false
	local function closer(code, signal)
		if closed then return end
		closed = true

		handle:close()
		stdout:read_stop() stdout:close()
		stderr:read_stop() stderr:close()
		closeCb(getRetVal(stdoutData, stderrData, code, signal))
	end
	handle = uv.spawn(..., {
		cwd = cwd,
		args = { select(2, ...) },
		stdio = { nil, stdout, stderr }
	}, closer)
	stdout:read_start(function(err, data)
		assert(not err, err)
		table.insert(stdoutData, data)
	end)
	stderr:read_start(function(err, data)
		assert(not err, err)
		table.insert(stderrData, data)
	end)
	return function() return closed end
end

local function doJsThings()
	local js = req("euclidian.lib.async.js")
	local promise = js.promise
	local a = js.a

	local function doCmd(...)
		local args = {...}
		return promise.new(function(res, rej)
			spawn(function(ret)
				(ret.code == 0 and res or rej)(ret)
			end, unpack(args))
		end)
	end
	doCmd("git", "status"):andThen(function(val)
		print(val)
	end)
	local val = a.wait(doCmd("git", "status"))
end

local zig = req("euclidian.lib.async.zig")

local function doZigThings()
	local function doCmd(...)
		local ret
		local isClosed = spawn(function(val)
			ret = val
		end, ...)
		zig.suspend()
		while not isClosed() do
			-- zig.suspend()
			zig.suspend(function(me)
				-- put some sort of io/evented operation here so the event loop can check on stuff
				uv.run("once")
				-- turns out the equivalent zig code causes a segfault if a frame resumes itself too many times
				-- this type of stuff should be put into some sort of event loop/scheduler
				zig.resume(me)
			end)
		end
		return ret
	end
	-- local frame = zig.async(doCmd, "git", "status")
	-- print(zig.nosuspendAwait(frame))
	-- print(zig.nosuspend(doCmd, "git", "status"))
	
	zig.async(function()
		local cmds = {
			{"git", "status"},
			{"ls"},
			{"sleep", "4"},
		}
		for i, cmd in ipairs(cmds) do
			cmds[i] = zig.async(doCmd, unpack(cmd))
		end
		for i, cmd in ipairs(cmds) do
			print(zig.await(cmd))
		end
	end)
end

-- print "Js stuff"
-- doJsThings ()
-- print "done js stuff"

print "Zig stuff"
doZigThings ()
print "done zig stuff"
