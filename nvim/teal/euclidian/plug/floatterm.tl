
local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local a <const> = vim.api

local key = ""
local shell = vim.fn.has("win32") and "powershell.exe" or "bash"
local termopenOpts: {string:any} = {}
local type Dialog = dialog.Dialog
local record floatterm
	record SetupOpts
		toggle: string

		wid: number
		hei: number
		row: number
		col: number

		centered: boolean | Dialog.Opts.Center
		border: nvim.Window.Config.Border

		shell: string
		termopenOpts: {string:any}
	end

	metamethod __call: function(floatterm, floatterm.SetupOpts): floatterm
end

local d: Dialog
local openTerm: function()
local hideTerm: function()

local function addShowMappings()
	nvim.setKeymap("n", key, openTerm, { noremap = true, silent = true })
end

local function addHideMappings()
	local b <const> = d:ensureBuf()
	b:setKeymap("n", key, hideTerm, { noremap = true, silent = true })
	b:setKeymap("t", key, hideTerm, { noremap = true, silent = true })
	nvim.autocmd("WinLeave", nil, hideTerm, { buffer = b.id, once = true })
end

local getBuf: function(): nvim.Buffer

do
	local shown = false
	openTerm = function()
		shown = true
		getBuf()
		d:show():win():setOption("winblend", 8)
		d:focus()
	end

	hideTerm = function()
		if shown then
			shown = false
			d:hide()
			addShowMappings()
		end
	end
end

getBuf = function(): nvim.Buffer
	local buf <const> = d:ensureBuf()
	if buf:getOption("buftype") ~= "terminal" then
		buf:setOption("modified", false)
		buf:call(function()
			vim.fn.termopen(shell, termopenOpts)
		end)
		addHideMappings()
	end
	return buf
end

function floatterm.channel(): integer
	return getBuf():getOption("channel")
end

local chansend <const> = a.nvim_chan_send

function floatterm.send(s: string): boolean
	local buf <const> = getBuf()
	if not buf:isValid() then
		return false
	end
	local channel <const> = buf:getOption("channel")
	chansend(channel, s)
	return true
end

return setmetatable(floatterm, {
	__call = function(self: floatterm, opts: floatterm.SetupOpts): floatterm
		opts = opts or {}
		key = opts.toggle or key
		shell = opts.shell or shell
		termopenOpts = opts.termopenOpts or termopenOpts

		if d then
			d:close()
			d = nil
		end

		d = dialog.new{
			wid = opts.wid or 0.9, hei = opts.hei or 0.85,
			row = opts.row, col = opts.col,
			centered = opts.centered or true,
			border = opts.border,

			interactive = true,
			hidden = true,
		}

		addShowMappings()

		nvim.newCommand{
			name = "FloatingTerminal",
			body = openTerm,
			nargs = 0,
			bar = true,
			overwrite = true,
		}

		nvim.newCommand{
			name = "FloatingTerminalSend",
			body = function(...: string)
				local buf <const> = getBuf()
				local channel <const> = buf:getOption("channel")
				chansend(channel, table.concat({...}, " "))
				chansend(channel, "\n")
			end,
			nargs = "+",
			overwrite = true,
		}

		return self
	end,
})
