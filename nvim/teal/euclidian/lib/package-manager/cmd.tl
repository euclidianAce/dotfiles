
local uv <const> = vim.loop
local ev <const> = require("euclidian.lib.ev")
local tree <const> = require("euclidian.lib.package-manager.tree")

local record CommandOpts
	{string}
	cwd: string
end

local function reader(t: thread, evName: string, streamName: string): function(string, string)
	return function(err: string, data: string)
		assert(not err, err)
		if data then
			ev.queueForThread(t, evName, streamName, data)
		end
	end
end

-- create a worker for the current event loop that emits events on:
--    command start
--    stdout
--    stderr
--    command done
-- additionally, the command will be killed when the msTimeout is reached
local function runCmd(evName: string, msTimeout: number, opts: CommandOpts)
	assert(opts)

	local cmdName <const> = opts[1]
	local args <const>: {string} = {}
	for i = 2, #opts do
		args[i-1] = opts[i]
	end

	-- stdin, stdout, stderr
	local stdio <const> = {uv.new_pipe(), uv.new_pipe(), uv.new_pipe()}

	local currentThread <const> = coroutine.running()

	ev.queueForThread(currentThread, evName, "start")
	local timeoutTimer <const> = uv.new_timer()

	local handle: uv.Handle
	local closed = false
	local function closer(a: any, b: any)
		if closed then return end
		closed = true
		ev.queueForThread(currentThread, evName, "done")
		handle:close()

		stdio[1]:close()
		stdio[2]:close() stdio[2]:read_stop()
		stdio[3]:close() stdio[3]:read_stop()
		timeoutTimer:close() timeoutTimer:stop()
	end

	handle = uv.spawn(cmdName, {
		cwd = opts.cwd,
		args = args,
		stdio = stdio,
	}, closer) as uv.Handle

	stdio[2]:read_start(reader(currentThread, evName, "stdout"))
	stdio[3]:read_start(reader(currentThread, evName, "stderr"))

	timeoutTimer:start(msTimeout, 0, closer)

	ev.worker(function()
		ev.waitUntil(function(): boolean
			return closed
		end)
	end)
end

local defaultTimeout <const> = 60000
local luarocks <const> = {}
do
	local function cmd(evKind: string, ...: string)
		runCmd(evKind, defaultTimeout, {"luarocks", "--tree", tree.luarocks, "--lua-version=5.1", ...})
	end

	function luarocks.install(evKind: string, rock: string)
		cmd(evKind, "install", rock)
	end

	function luarocks.remove(evKind: string, rock: string)
		cmd(evKind, "remove", rock)
	end

	function luarocks.list(evKind: string)
		cmd(evKind, "list")
	end
end

local git <const> = {}
do
	function git.clone(evKind: string, repo: string, dest: string)
		runCmd(evKind, defaultTimeout, {"git", "clone", "https://github.com/" .. repo, dest})
	end

	function git.pull(evKind: string, dir: string)
		runCmd(evKind, defaultTimeout, {"git", "pull", cwd = dir})
	end
end

local function wrapAsync(msInterval: number, f: function)
	local l <const> = ev.loop(f)
	local t <const> = uv.new_timer()
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

