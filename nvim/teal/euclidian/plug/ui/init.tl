local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local z <const> = require("euclidian.lib.azync")
local menu <const> = require("euclidian.lib.menu")

local function wait(ms: integer)
	z.suspend(function(me: z.Frame<nil>)
		vim.defer_fn(function() z.resume(me) end, ms)
	end)
end

local function flashWindow(win: nvim.Window)
	local orig <const> = win:getOption("winhighlight")
	z.async(function()
		for _ = 1, 3 do
			vim.schedule(function()
				if win:isValid() then
					win:setOption("winhighlight", "Normal:STLNormal,NormalFloat:STLInsert")
				end
			end)
			wait(250)
			vim.schedule(function()
				if win:isValid() then
					win:setOption("winhighlight", orig)
				end
			end)
			wait(150)
		end
	end)
end

local function promptDialog(prompt: string): string
	local me <const> = z.currentFrame()
	local minwid <const> = #prompt + 10
	local d <const> = dialog.new{
		centered = { horizontal = true },
		wid = minwid,
		hei = 1,
		row = -1,
		interactive = true,
		ephemeral = true,
		border = "none",
	}
	local result: string
	d:setPrompt(
		prompt,
		function(res: string)
			result = res
			d:close()
			z.resume(me)
		end,
		function()
			d:close()
			z.resume(me)
		end
	)
	d:buf():attach(true, {
		on_lines = function()
			d:fitTextPadded(10, 0, minwid, 1, nil, nil):centerHorizontal()
		end
	})
	flashWindow(d:win())
	vim.schedule(function() nvim.command("startinsert") end)
	z.suspend()
	return result
end

vim.ui.input = function(opts: vim.ui.InputOpts, confirm: function(string))
	assert(confirm)
	z.async(function()
		local res <const> = promptDialog(opts.prompt)
		if res then
			confirm(res)
		end
	end)
end

local function clamp(n: integer, a: integer, b: integer): integer
	return math.min(math.max(n, a), b)
end

vim.ui.select = function(items: {any}, opts: vim.ui.SelectOpts, confirm: function(any, integer))
	assert(confirm)
	local inspector = opts.format_item or tostring

	local accordionItems: {menu.Accordion.Item} = {
		{ opts.prompt or "Select one of:" },
	}

	local longest = 0
	for i, v in ipairs(items) do
		local str = inspector(v) or "<???>"
		if #str > longest then
			longest = #str
		end
		accordionItems[i + 1] = { str, function() confirm(v, i) end }
	end

	local hei <const> = clamp(#accordionItems, 4, nvim.ui().height // 4)
	local d <const> = dialog.new{
		centered = { horizontal = true },
		interactive = true,
		ephemeral = true,
		wid = clamp(longest + 5, 20, nvim.ui().width // 2),
		hei = hei,
		row = -hei - 4,
		border = "none",
	}
	flashWindow(d:win())
	local function cancel()
		confirm(nil, nil)
		d:close()
	end
	local buf <const> = d:buf()
	buf:setKeymap("n", "<c-c>", cancel, { silent = true })
	buf:setKeymap("n", "<esc>", cancel, { silent = true })
	z.async(menu.new.accordion(accordionItems), d)
end
