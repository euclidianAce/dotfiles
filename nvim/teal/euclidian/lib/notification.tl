
local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")

local type Dialog = dialog.Dialog

local record Opts
	msTimeout: integer
end

local notification <const> = {
	Opts = Opts,
}

local function longestLen(arr: {string}): integer
	local l = 0
	for _, v in ipairs(arr) do
		if #v > l then l = #v end
	end
	return l
end

local record Node
	next: Node
	d: Dialog
end
local root: Node = {}

local function lastNode(): Node
	local n = root
	while n.next do
		n = n.next
	end
	return n
end

local function insert(d: Dialog)
	lastNode().next = { d = d }
end

local function moveDown(d: Dialog, n: integer)
	if n > 0 then
		local win <const> = d:win()
		local c = win:getConfig()
		c.row = (c.row as {boolean:integer})[false] + n
		win:setConfig(c)
	end
end

local borderOffset <const> = 3

local function dismiss(d: Dialog)
	local n = root
	local prev: Node
	while n and n.d ~= d do
		prev = n
		n = n.next
	end

	prev.next = n.next
	local acc = 0

	if n.d then
		acc = n.d:win():getHeight() + borderOffset
		n.d:close()
	end
	n = n.next

	while n do
		moveDown(n.d, acc)
		n = n.next
	end
end

function notification.create(txt: string, opts: Opts)
	local msTimeout <const> = opts and opts.msTimeout or 2500

	local lines <const> = vim.split(txt, "\n")
	local len <const> = longestLen(lines)

	local uiHeight <const> = nvim.ui().height
	local dOpts <const>: Dialog.Opts = {
		row = uiHeight - #lines - 5, col = - 4 - len,
		wid = len, hei = #lines,
		interactive = false,
	}

	local n <const> = lastNode()
	if n.d then
		local conf <const> = n.d:win():getConfig()
		dOpts.row = (conf.row as {boolean:integer})[false] - dOpts.hei - borderOffset
	end

	local d <const> = dialog.new(dOpts)
	d:setLines(lines)
	insert(d)

	vim.defer_fn(function()
		dismiss(d)
	end, msTimeout)
end

return notification
