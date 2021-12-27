local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local z <const> = require("euclidian.lib.azync")
local quick <const> = require("euclidian.lib.dialog.quick")

-- TODO: rip this out of the package manager and into its own library
local menu <const> = require("euclidian.plug.package-manager.menu")

local function wait(ms: integer)
	z.suspend(function(me: z.Frame<nil>)
		vim.defer_fn(function() z.resume(me) end, ms)
	end)
end

local function flashWindow(win: nvim.Window)
	local orig <const> = win:getOption("winhighlight")
	z.async(function()
		for _ = 1, 3 do
			vim.schedule(function() win:setOption("winhighlight", "Normal:STLNormal,NormalFloat:STLInsert") end)
			wait(250)
			vim.schedule(function() win:setOption("winhighlight", orig) end)
			wait(150)
		end
	end)
end

vim.ui.input = function(opts: vim.ui.InputOpts, confirm: function(string))
	assert(confirm)
	z.async(function()
		local result <const> = quick.prompt(opts.prompt, {
			centered = { horizontal = true },
			wid = #opts.prompt + 10,
			hei = 1,
			row = -1,
			interactive = true,
			ephemeral = true,
			border = "none",
		}, function(d: dialog.Dialog) flashWindow(d:win()) end)
		confirm(result)
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
	z.async(
		menu.new.accordion(accordionItems),
		{
			centered = { horizontal = true },
			interactive = true,
			ephemeral = true,
			wid = clamp(longest + 5, 20, nvim.ui().width // 2),
			hei = hei,
			row = -hei - 4,
			border = "none",
		},
		function(d: dialog.Dialog)
			flashWindow(d:win())
			local function cancel()
				confirm(nil, nil)
				d:close()
			end
			local buf <const> = d:buf()
			buf:setKeymap("n", "<c-c>", cancel, { noremap = true, silent = true })
			buf:setKeymap("n", "<esc>", cancel, { noremap = true, silent = true })
		end
	)
end
