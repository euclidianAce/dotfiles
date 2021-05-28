
local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local a <const> = vim.api

local key = ""
local record FloatTermSetupOpts
	toggle: string
end
local floatterm <const> = {
	FloatTermSetupOpts = FloatTermSetupOpts,
}

local d: dialog.Dialog
local openTerm: function()
local hideTerm: function()

local function addMappings()
	if d:win():isValid() then
		-- window is visible, add mappings to hide it
		d:ensureBuf():setKeymap("n", key, hideTerm, { noremap = true, silent = true })
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
	local channel <const> = getBuf():getOption("channel")
	chansend(channel, s)
	return true
end

function floatterm.setup(opts: FloatTermSetupOpts)
	opts = opts or {}

	d = dialog.new{
		wid = 0.9, hei = 0.85,
		centered = true,
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
end

return floatterm
