local a <const> = vim.api
local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local z <const> = require("euclidian.lib.async.zig")
local quick <const> = {}

local type Dialog = dialog.Dialog
local type Opts = dialog.Dialog.Opts

function quick.prompt(txt: string, opts: Opts): string
	local origId <const> = nvim.Window().id
	local d <const> = dialog.new(opts or {
		wid = 45, hei = 1,
		centered = true,
		interactive = true,
		ephemeral = true,
	})
	d:ensureWin():setVar("QuickDialog", true)
	d:ensureBuf():attach(false, {
		on_lines = function()
			d:fitTextPadded(1, 0, 45, nil, nil, 1):centerHorizontal()
		end
	})
	d:addKeymap(
		"n", "<esc>",
		function() d:close() end,
		{ silent = true, noremap = true }
	)
	local res: string
	z.suspend(function(me: z.Frame<nil>)
		d:setPrompt(txt, function(result: string)
			res = result
			a.nvim_set_current_win(origId)
			d:close()
			z.resume(me)
		end)
	end)
	d:unsetPrompt()
	return res
end

local function waitForKey(d: Dialog, ...: string): string
	local keys <const> = {...}
	local function delKeymaps()
		vim.schedule(function()
			for _, key in ipairs(keys) do
				d:delKeymap("n", key)
			end
		end)
	end
	local pressed: string
	local me <const> = assert(z.currentFrame(), "attempt to waitForKey not in a coroutine")
	vim.schedule(function()
		for _, key in ipairs(keys) do
			d:addKeymap("n", key, function()
				pressed = key
				delKeymaps()
				z.resume(me)
			end, { noremap = true, silent = true })
		end
	end)
	z.suspend()
	return pressed
end

function quick.yesOrNo(pre: string, affirm: string, deny: string, opts: Opts): boolean
	local origId <const> = nvim.Window().id
	local d = dialog.new(opts or {
		wid = 45, hei = 3,
		centered = true,
		interactive = true,
		ephemeral = true,
	})
	d:ensureWin():setVar("QuickDialog", true)
	affirm = affirm or "Yes"
	deny = deny or "No"
	d:setLines{
		pre,
		affirm,
		deny,
	}:fitTextPadded(2, 1, 45, 3):center()
	d:win():setOption("cursorline", true)
	local ln: integer
	repeat
		waitForKey(d, "<cr>")
		ln = d:getCursor()
	until ln > 1
	a.nvim_set_current_win(origId)
	d:close()
	return ln == 2
end


return quick
