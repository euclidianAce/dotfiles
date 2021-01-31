
local tree <const> = require("euclidian.lib.package-manager.tree")
local ev <const> = require("euclidian.lib.ev")
local packagespec <const> = require("euclidian.lib.package-manager.packagespec")
local uv <const> = vim.loop

local Spec <const> = packagespec.Spec

local record cmdCallbacks
	stdout: function(string)
	stderr: function(string)

	start: function
	close: function
end
local record cmdOpts
	on: cmdCallbacks
	cwd: string
	timeout: number
	command: {string}
	thread: thread
end

local function runCmd(o: cmdOpts)
	assert(o)
	local cbs <const> = o.on or {}

	local cmdName <const> = o.command[1]
	local args <const>: {string} = {}
	for i = 2, #o.command do
		args[i-1] = o.command[i]
	end

	local stdout <const> = uv.new_pipe(false)
	local stderr <const> = uv.new_pipe(false)

	local handle: uv.Handle
	local timeoutTimer <const> = uv.new_timer()
	local closed = false
	local function closer()
		if closed then return end
		closed = true

		handle:close()
		stdout:close() stdout:read_stop()
		stderr:close() stderr:read_stop()
		timeoutTimer:stop() timeoutTimer:close()

		if cbs.close then
			cbs.close()
		end
	end

	handle = assert(uv.spawn(cmdName, {
		cwd = o.cwd,
		args = args,
		stdio = { nil, stdout, stderr },
	}, closer)) as uv.Handle

	stdout:read_start(function(err: string, data: string)
		assert(not err, err)
		if data and cbs.stdout then
			cbs.stdout(data)
		end
	end)
	stderr:read_start(function(err: string, data: string)
		assert(not err, err)
		if data and cbs.stderr then
			cbs.stderr(data)
		end
	end)

	timeoutTimer:start(o.timeout or 30000, 0, closer)

	if cbs.start then
		cbs.start()
	end
end

local function eventedCmd(opts: cmdOpts)
	local thread <const> = opts.thread or coroutine.running()
	local closed = false
	local command <const>: {string} = opts.command
	local optsOn: cmdCallbacks = opts.on or {}
	runCmd{
		command = command,
		cwd = opts.cwd,
		on = {
			stdout = function(data: string)
				ev.queue(thread, { kind = "stdout", data })
				if optsOn.stdout then
					vim.schedule(function()
						optsOn.stdout(data)
					end)
				end
			end,
			stderr = function(data: string)
				ev.queue(thread, { kind = "stderr", data })
				if optsOn.stderr then
					vim.schedule(function()
						optsOn.stderr(data)
					end)
				end
			end,
			start = function()
				ev.queue(thread, { kind = "start", command })
				if optsOn.start then
					vim.schedule(optsOn.start)
				end
			end,
			close = function()
				ev.queue(thread, { kind = "finish", command })
				closed = true
				if optsOn.close then
					vim.schedule(optsOn.close)
				end
			end,
		},
	}

	ev.anchor(function(): boolean
		return not closed
	end)
end

local git <const> = {}

function git.clone(p: Spec)
	assert(p.kind == "git", "Attempt to git.clone a non git package")
	eventedCmd{
		command = {"git", "clone", "https://github.com/" .. p.repo, p.repo:match("[^/]+$")}
	}
end

function git.pull(p: Spec)
	assert(p.kind == "git", "Attempt to git.pull a non git package")
	eventedCmd{
		command = {"git", "pull"},
		cwd = tree.neovim .. "/" .. p.repo:match("[^/]+$"),
	}
end

-- TODO: luarocks commands
local luarocks <const> = {}
function luarocks.list()
end

function luarocks.install()
end

function luarocks.remove()
end

return {
	run = runCmd,
	runEvented = eventedCmd,
	git = git,
	luarocks = luarocks,
}
