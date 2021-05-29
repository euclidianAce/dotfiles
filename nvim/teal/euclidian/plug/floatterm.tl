
local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local a <const> = vim.api

local key = ""
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
	end

	metamethod __call: function(floatterm, floatterm.SetupOpts): floatterm
end

local d: Dialog
local openTerm: function()
local hideTerm: function()

local function addMappings()
	if d:win():isValid() then
		-- window is visible, add mappings to hide it
		d:ensureBuf():setKeymap("n", key, hideTerm, { noremap = true, silent = true })
		d:ensureBuf():setKeymap("t", key, hideTerm, { noremap = true, silent = true })
	else
		-- window is not visible, add mappings to show it
		nvim.setKeymap("n", key, openTerm, { noremap = true, silent = true })
	end
end

local getBuf: function(): nvim.Buffer

openTerm = function()
	getBuf()
	d:show():win():setOption("winblend", 8)
	addMappings()
end

hideTerm = function()
	d:hide()
	addMappings()
end

getBuf = function(): nvim.Buffer
	local buf <const> = d:ensureBuf()
	buf:setOption("modified", false)
	if buf:getOption("buftype") ~= "terminal" then
		buf:call(function() vim.fn.termopen("bash") end)
	end
	addMappings()
	return d:buf()
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

		addMappings()

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
