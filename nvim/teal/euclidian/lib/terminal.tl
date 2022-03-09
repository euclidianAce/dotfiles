local nvim <const> = require("euclidian.lib.nvim")

local record Terminal
	record OpenOpts
		clearEnv: boolean
		cwd: string
		detach: boolean
		env: {string:string}
		onExit: function(integer, integer, integer, string)
		onStdout: function(integer, integer, {string}, string)
		onStderr: function(integer, integer, {string}, string)
		overlapped: boolean
		rpc: boolean
		stdoutBuffered: boolean
		stderrBuffered: boolean
		enum Stdin
			"null"
			"pipe"
		end
		stdin: Stdin
	end

	buf: nvim.Buffer
	cmd: string | {string}
	opts: OpenOpts
	channel: integer

	ensureOpen: function(Terminal)
end

local function copyOpts(o: Terminal.OpenOpts): {string:any}
	return {
		[vim.type_idx as string] = vim.types.dictionary,

		clear_env: boolean = o.clearEnv,
		cwd: string = o.cwd,
		detach: boolean = o.detach,
		env: {string:string} = o.env,
		on_exit: function() = o.onExit,
		on_stdout: function() = o.onStdout,
		on_stderr: function() = o.onStderr,
		overlapped: boolean = o.overlapped,
		rpc: boolean = o.rpc,
		stdout_buffered: boolean = o.stdoutBuffered,
		stderr_buffered: boolean = o.stderrBuffered,
		stdin: Terminal.OpenOpts.Stdin = o.stdin,
	} as Terminal.OpenOpts
end

local termopen <const> = vim.fn.termopen as function(string | {string}, {string:any}): integer

local function ensureOpen(t: Terminal)
	if t.buf:isValid() and t.buf:getOption("buftype") == "terminal" then
		return
	end
	if not t.buf:isValid() then
		t.buf = nvim.createBuf(false, true)
		t.channel = nil
	end
	if not t.channel or t.channel < 0 then
		t.buf:call(function()
			t.channel = termopen(t.cmd, copyOpts(t.opts))
		end)
	end
end

Terminal.ensureOpen = ensureOpen

local function create(
	cmd: string | {string},
	opts: Terminal.OpenOpts,
	buf: nvim.Buffer
): Terminal
	if not buf then
		buf = nvim.createBuf(false, true)
	end
	return setmetatable({
		buf = buf,
		cmd = cmd,
		opts = opts,
	}, { __index = Terminal })
end

local function open(
	cmd: string | {string},
	opts: Terminal.OpenOpts,
	buf: nvim.Buffer
): Terminal
	local term <const> = create(cmd, opts, buf)
	ensureOpen(term)
	return term
end

local terminal <const> = {
	Terminal = Terminal,
	create = create,
	open = open,
}

local jobstop <const> = vim.fn.jobstop as function(integer)

function Terminal:close()
	if self.buf:isValid() then
		self.buf:delete{ force = true }
	end
	jobstop(self.channel)
end

function Terminal:send(s: string): boolean
	if not self.buf:isValid() then
		return false
	end
	nvim.api.chanSend(self.channel, s)
	return true
end

return terminal
