local nvim <const> = require("euclidian.lib.nvim")
local color <const> = require("euclidian.lib.color")
local dialog <const> = require("euclidian.lib.dialog")
local z <const> = require("euclidian.lib.azync")
local menu <const> = require("euclidian.lib.menu")

local hi <const> = color.scheme.hi
local windowhl <const> = "EuclidianUIWindowHl"
hi[windowhl] = hi.STLNormal

local border <const> = dialog.getDefaultBorder()
for _, v in ipairs(border) do
	v[2] = windowhl
end

local function safeSetOpt(win: nvim.Window, name: string, value: string)
	vim.schedule(function()
		if win:isValid() then
			win:setOption(name, value)
		end
	end)
end

local function setupWindow(win: nvim.Window)
	safeSetOpt(win, "winhighlight", "Normal:" .. windowhl .. ",NormalFloat:" .. windowhl)
end

local function promptDialog(prompt: string): string
	local me <const> = z.currentFrame()
	local ui <const> = nvim.ui()
	local minwid <const> = ui.width // 2
	local maxwid <const> = ui.width - 4
	local d <const> = dialog.new{
		centered = { horizontal = true },
		wid = minwid,
		hei = 1,
		row = -5,
		interactive = true,
		ephemeral = true,
		border = {
			{ " ", windowhl },
			{ " ", windowhl },
			{ " ", windowhl },
			{ " ", windowhl },
			{ " ", windowhl },
			{ " ", windowhl },
			{ " ", windowhl },
			{ " ", windowhl },
		}
	}
	local result: string
	local function close()
		d:close()
		z.resume(me)
	end
	d:setPrompt(
		prompt,
		function(res: string)
			result = res
			close()
		end,
		close
	)
	local buf <const> = d:buf()
	buf:attach(true, {
		on_lines = function()
			d:fitTextPadded(3, 0, minwid, 1, maxwid, nil):centerHorizontal()
		end
	})
	setupWindow(d:win())
	buf:setKeymap("n", "<esc>", close)
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
	local inspector <const> = opts.format_item or tostring

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
		border = border,
	}
	setupWindow(d:win())
	local function cancel()
		confirm(nil, nil)
		d:close()
	end
	local buf <const> = d:buf()
	buf:setKeymap("n", "<c-c>", cancel, { silent = true })
	buf:setKeymap("n", "<esc>", cancel, { silent = true })
	z.async(menu.new.accordion(accordionItems), d)
end
