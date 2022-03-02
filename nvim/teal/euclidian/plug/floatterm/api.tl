local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")

local type Dialog = dialog.Dialog

local floatterm <const> = {
	show: function() = nil,
	hide: function() = nil,
}

local d: Dialog
local shell: string
local key: string
local termopenOpts: {string:any}
local windowOpts: {string:any}

function floatterm.setTermOptions(opts: {string:any}) termopenOpts = opts end
function floatterm.setShell(s: string) shell = s end
function floatterm.setToggleKey(k: string) key = k end
function floatterm.setWindowOpts(opts: {string:any}) windowOpts = opts end

local function addShowMappings()
	vim.keymap.set("n", key, floatterm.show, { silent = true })
end

local function applyWindowOpts(w: nvim.Window)
	for k, v in pairs(windowOpts) do
		(w.setOption as function(nvim.Window, string, any))(w, k, v)
	end
end

function floatterm.init(opts: Dialog.Opts)
	d = dialog.new(opts)
	addShowMappings()
end

function floatterm.deinit()
	if d then
		d:close()
		d = nil
	end
end

function floatterm.buffer(): nvim.Buffer
	return d:ensureBuf()
end

local function addHideMappings()
	local b <const> = d:ensureBuf()
	b:setKeymap("n", key, floatterm.hide, { silent = true })
	b:setKeymap("t", key, floatterm.hide, { silent = true })
	nvim.autocmd("WinLeave", nil, floatterm.hide, { buffer = b.id, once = true })
end

local getBuf: function(): nvim.Buffer

do
	local shown = false
	floatterm.show = function()
		shown = true
		getBuf()
		d:show()
		local win <const> = d:win()
		win:setOption("winblend", 8)
		applyWindowOpts(win)
		d:focus()
	end

	floatterm.hide = function()
		if shown then
			shown = false
			d:hide()
			addShowMappings()
		end
	end
end

local channelId: integer

getBuf = function(): nvim.Buffer
	local buf <const> = d:ensureBuf()
	if buf:getOption("buftype") ~= "terminal" then
		buf:setOption("modified", false)
		buf:call(function()
			local opts = termopenOpts
			if not opts or not next(opts) then
				opts = vim.empty_dict() as {string:any}
			end
			channelId = vim.fn.termopen(shell, opts) as integer
			-- if channelId == 0 then
				-- invalid args
			-- elseif channelId == -1 then
				-- not executable
			-- else
				-- success
			-- end
		end)
		addHideMappings()
	end
	return buf
end

function floatterm.channel(): integer
	return channelId
end

function floatterm.send(s: string): boolean
	local buf <const> = getBuf()
	if not buf:isValid() then
		return false
	end
	nvim.api.chanSend(channelId, s)
	return true
end

return floatterm
