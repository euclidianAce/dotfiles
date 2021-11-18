local nvim <const> = require("euclidian.lib.nvim")

local record OpNum
	leaders: {string}
	add: function(string): OpNum
	enable: function()

	_start: function()
	_finish: function()
end

local opnum <const>: OpNum = {
	leaders = {
		-- from :h operator
		"c",
		"d",
		"y",
		"g~",
		"gu",
		"gU",
		"!",
		"=",
		"gq",
		"gw",
		"g?",
		">",
		"<",
		"zf",
		"g@",
	},
}

local record Saved
	win: nvim.Window
	number: boolean
	relativenumber: boolean
end
local old: Saved

opnum._start = vim.schedule_wrap(function()
	local win <const> = nvim.Window()
	old = {
		win = win,
		number = win:getOption("number"),
		relativenumber = win:getOption("relativenumber"),
	}

	win:setOption("relativenumber", true)
end)

opnum._finish = vim.schedule_wrap(function()
	if old and old.win:isValid() then
		old.win:setOption("number", old.number)
		old.win:setOption("relativenumber", old.relativenumber)
	end
end)

function opnum.add(leader: string): OpNum
	table.insert(opnum.leaders, leader)
	return opnum
end

function opnum.enable()
	for _, leader in ipairs(opnum.leaders) do
		nvim.setKeymap("n", leader, "<cmd>call v:lua.require'euclidian.plug.opnum'._start()<cr>" .. leader, { noremap = true, silent = true })
	end
	nvim.setKeymap("o" as vim.Mode, "<esc>", "<cmd>call v:lua.require'euclidian.plug.opnum'._finish()<cr>", { noremap = true, silent = true })
	nvim.setKeymap("o" as vim.Mode, "<c-c>", "<cmd>call v:lua.require'euclidian.plug.opnum'._finish()<cr>", { noremap = true, silent = true })

	nvim.augroup("ResetLineNumberAfterOperator", {
		{ {"CursorMoved", "CursorMovedI", "BufLeave", "TextYankPost"}, "*", opnum._finish }
	}, true)
end

return opnum
