
local dialog <const> = require("euclidian.lib.dialog")

local type Dialog = dialog.Dialog

local record Opts
	msTimeout: integer
end

local notification <const> = {
	Opts = Opts,
}

local record Container
	d: Dialog
	idx: integer
end

local stack <const>: {Container} = {}

local function longestLen(arr: {string}): integer
	local l = 0
	for _, v in ipairs(arr) do
		if #v > l then l = #v end
	end
	return l
end

local function shift(d: Dialog, n: integer)
	if n == 0 then return end
	local win <const> = d:win()
	local c = win:getConfig()
	c.row = (c.row as {boolean:integer})[false] + n
	win:setConfig(c)
end

local borderOffset <const> = 2

local function dismiss(c: Container)
	local height <const> = c.d:win():getHeight() + borderOffset
	c.d:close()
	table.remove(stack, c.idx)
	for i = c.idx, #stack do
		stack[i].idx = i
		shift(stack[i].d, height)
	end
end

local function insert(d: Dialog): Container
	local c <const> = {
		d = d,
		idx = 1,
	}
	local height <const> = d:win():getHeight() + borderOffset
	table.insert(stack, 1, c)
	for i = 2, #stack do
		stack[i].idx = i
		shift(stack[i].d, -height)
	end
	return c
end

function notification.create(str: string, opts: Opts)
	opts = opts or {}
	local msTimeout <const> = opts.msTimeout or 2500

	local lines <const> = vim.split(str, "\n")
	local len <const> = longestLen(lines)

	local dOpts <const>: Dialog.Opts = {
		row = -#lines - 5, col = -4 - len,
		wid = len, hei = #lines,
		interactive = false,
	}

	local d <const> = dialog.new(dOpts)
	d:setLines(lines)
	local c <const> = insert(d)

	vim.defer_fn(function()
		dismiss(c)
	end, msTimeout)
end

return notification
