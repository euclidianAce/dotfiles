
local window <const> = require("euclidian.lib.window")
local a <const> = vim.api

local record Dialog
	record Opts
		wid: number
		hei: number
		row: number
		col: number
	end
	
	buf: window.t.BufId
	win: window.t.WinId
end

local function new(): Dialog
	local win <const>, buf <const> = window.new.floating(10, 10, 50, 5)
	a.nvim_buf_set_option(buf, "buftype", "nofile")
	a.nvim_buf_set_option(buf, "modifiable", false)
	a.nvim_win_set_option(win, "winblend", 5)
	return setmetatable({
		win = win,
		buf = buf,
	}, { __index = Dialog })
end
function Dialog:setTxt(txt: {string}): Dialog
	a.nvim_buf_set_option(self.buf, "modifiable", true)
	a.nvim_buf_set_lines(self.buf, 0, -1, false, txt)
	a.nvim_buf_set_option(self.buf, "modifiable", false)
	return self
end
function Dialog:setCursor(row: number, col: number): Dialog
	a.nvim_win_set_cursor(self.win, {row, col})
	return self
end
function Dialog:getCursor(): number, number
	local pos <const> = a.nvim_win_get_cursor(self.win)
	return pos[1], pos[2]
end
function Dialog:getLine(n: number): string
	return a.nvim_buf_get_lines(self.buf, n-1, n, false)[1]
end
function Dialog:setWin(o: Dialog.Opts): Dialog
	a.nvim_win_set_config(self.win, {
		relative = "editor",
		row = assert(o.row, "no row"), col = assert(o.col, "no col"),
		width = assert(o.wid, "no wid"), height = assert(o.hei, "no hei"),
	})
	return self
end
function Dialog:addKeymap(mode: string, lhs: string, data: string): Dialog
	a.nvim_buf_set_keymap(
		self.buf, mode, lhs,
		string.format("<cmd>lua require'euclidian.lib.package-manager.interface'.advanceDialog(%q)<CR>", data or ""),
		{ silent = true, noremap = true }
	)
	return self
end
function Dialog:delKeymap(mode: string, lhs: string): Dialog
	a.nvim_buf_del_keymap(self.buf, mode, lhs)
	return self
end
function Dialog:setWinOpt(optName: string, val: any): Dialog
	a.nvim_win_set_option(self.win, optName, val)
	return self
end
function Dialog:setBufOpt(optName: string, val: any): Dialog
	a.nvim_buf_set_option(self.buf, optName, val)
	return self
end
function Dialog:close()
	a.nvim_win_close(self.win, true)
end

return {
	new = new,
	Dialog = Dialog,
}
