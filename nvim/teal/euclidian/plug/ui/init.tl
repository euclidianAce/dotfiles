local nvim <const> = require("euclidian.lib.nvim")
local color <const> = require("euclidian.lib.color")
local dialog <const> = require("euclidian.lib.dialog")
local z <const> = require("euclidian.lib.azync")
local menu <const> = require("euclidian.lib.menu")

local function wait(ms: integer)
	z.suspend(function(me: z.Frame<nil>)
		vim.defer_fn(function() z.resume(me) end, ms)
	end)
end

local borderhl <const> = "EuclidianUIBorder"

local border <const> = dialog.getDefaultBorder()
for _, v in ipairs(border) do
	v[2] = borderhl
end

local function setBorderHl(fg: integer, bg: integer)
	nvim.api.setHl(0, borderhl, { fg = fg, bg = bg })
end
local hi <const> = color.scheme.hi

local origColor <const> = hi.Delimiter
local destColor <const> = hi.STLNormal

setBorderHl(origColor[1], origColor[2])

local gradient <const>: {{integer, integer}} = {}

do
	local function lerp(p: number, from: number, to: number): number
		return from + (to - from) * p
	end

	local function lerpColors(
		p: number,
		from: {number, number, number}, -- hsv
		to: {number, number, number} -- hsv
	): integer -- hex
		local h: number = nil
		if from[1] and to[1] then
			h = lerp(p, from[1], to[1])
		elseif from[1] and p < 1 then
			h = from[1] * p
		elseif p > 0 then
			h = to[1] * p
		end

		local r, g, b = color.hsvToRgb(
			h,
			lerp(p, from[2], to[2]),
			lerp(p, from[3], to[3])
		)
		return color.rgbToHex(math.floor(r*255), math.floor(g*255), math.floor(b*255))
	end

	local normal <const> = hi.Normal
	local srcfg <const> = { color.rgbToHsv(color.hexToRgb(origColor[1] or normal[1])) }
	local srcbg <const> = { color.rgbToHsv(color.hexToRgb(origColor[2] or normal[2])) }

	local destfg <const> = { color.rgbToHsv(color.hexToRgb(destColor[1] or normal[1])) }
	local destbg <const> = { color.rgbToHsv(color.hexToRgb(destColor[2] or normal[2])) }

	table.insert(gradient, { origColor[1], origColor[2] })
	for p = 0, 1, 0.04 do
		local a = lerpColors(p, srcfg, destfg)
		local b = lerpColors(p, srcbg, destbg)
		table.insert(gradient, { a, b })
	end
	table.insert(gradient, { destColor[1], destColor[2] })
end

local function safeSetOpt(win: nvim.Window, name: string, value: string)
	vim.schedule(function()
		if win:isValid() then
			win:setOption(name, value)
		end
	end)
end

local function flashWindow(win: nvim.Window)
	local function doGradient(from: integer, to: integer)
		for i = from, to, to > from and 1 or -1 do
			setBorderHl(gradient[i][1], gradient[i][2])
			-- TODO:
			--   this seems to be the only way to make sure the updates are
			--   shown, drawing the border manually and using extmarks would probably
			--   be a lot better
			vim.cmd "mode"
			wait(10)
			if not win:isValid() then return end
		end
	end

	z.async(function()
		safeSetOpt(win, "winhighlight", "Normal:" .. borderhl .. ",NormalFloat:" .. borderhl)
		doGradient(1, #gradient)
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
		border = border,
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
			d:fitTextPadded(10, 0, minwid, 1, nil, nil):centerHorizontal()
		end
	})
	flashWindow(d:win())
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
		border = border,
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
