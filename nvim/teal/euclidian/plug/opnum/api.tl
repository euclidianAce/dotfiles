local nvim <const> = require("euclidian.lib.nvim")

local opnum <const> = {
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

	add: function(string) = nil,
	enable: function() = nil,

	start: function() = nil,
	finish: function() = nil,
}

local record Saved
	win: nvim.Window
	number: boolean
	relativenumber: boolean
end
local old: Saved

opnum.start = vim.schedule_wrap(function()
	local win <const> = nvim.Window()
	old = {
		win = win,
		number = win:getOption("number"),
		relativenumber = win:getOption("relativenumber"),
	}

	win:setOption("relativenumber", true)
end)

opnum.finish = vim.schedule_wrap(function()
	if old and old.win:isValid() then
		old.win:setOption("number", old.number)
		old.win:setOption("relativenumber", old.relativenumber)
	end
	old = nil
end)

function opnum.enable(...: string)
	for i = 1, select("#", ...) do
		table.insert(opnum.leaders, (select(i, ...)))
	end

	for _, leader in ipairs(opnum.leaders) do
		vim.keymap.set("n", leader, "<cmd>call v:lua.require'euclidian.plug.opnum.api'.start()<cr>" .. leader, { silent = true })
	end
	vim.keymap.set("o" as vim.Mode, "<esc>", "<cmd>call v:lua.require'euclidian.plug.opnum.api'.finish()<cr>", { silent = true })
	vim.keymap.set("o" as vim.Mode, "<c-c>", "<cmd>call v:lua.require'euclidian.plug.opnum.api'.finish()<cr>", { silent = true })

	local group <const> = "ResetLineNumberAfterOperator"
	nvim.api.createAugroup(group, { clear = true })
	nvim.api.createAutocmd(
		{"CursorMoved", "CursorMovedI", "BufLeave", "TextYankPost"},
		{
			pattern = "*",
			callback = opnum.finish,
			group = group,
		}
	)
end

return opnum
