
local window <const> = require("euclidian.lib.window")
local a <const> = vim.api

local record Dialog
	record Opts
		wid: number
		hei: number
		row: number
		col: number
	end
	
	buf: window.BufId
	win: window.WinId
end

local function setOpts(win: window.WinId, buf: window.BufId)
	a.nvim_buf_set_option(buf, "buftype", "nofile")
	a.nvim_buf_set_option(buf, "modifiable", false)
	a.nvim_win_set_option(win, "winblend", 5)
end

local function toDialog(win: window.WinId, buf: window.BufId): Dialog
	setOpts(win, buf)
	return setmetatable({
		win = win,
		buf = buf,
	}, { __index = Dialog })
end

local function new(x: number, y: number, wid: number, hei: number): Dialog
	return toDialog(window.floating(x or 10, y or 10, wid or 50, hei or 5))
end

local function centered(wid: number, hei: number): Dialog
	return toDialog(window.centeredFloat(wid or 50, hei or 5))
end

function Dialog:setLines(txt: {string}): Dialog
	a.nvim_buf_set_option(self.buf, "modifiable", true)
	a.nvim_buf_set_lines(self.buf, 0, -1, false, txt)
	a.nvim_buf_set_option(self.buf, "modifiable", false)
	return self
end
function Dialog:setText(edits: {{string, number, number, number, number}}): Dialog
	-- edit: {text, start_row, start_col, end_row, end_col}
	a.nvim_buf_set_option(self.buf, "modifiable", true)
	for _, edit in ipairs(edits) do
		a.nvim_buf_set_text(self.buf, edit[2], edit[3], edit[4], edit[5], {edit[1]})
	end
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
function Dialog:getLines(min: number, max: number): {string}
	return a.nvim_buf_get_lines(self.buf, min or 0, max or -1, false)
end
function Dialog:setWin(o: Dialog.Opts): Dialog
	a.nvim_win_set_config(self.win, {
		relative = "editor",
		row = assert(o.row, "no row"), col = assert(o.col, "no col"),
		width = assert(o.wid, "no wid"), height = assert(o.hei, "no hei"),
	})
	return self
end
function Dialog:addKeymap(mode: vim.Mode, lhs: string, rhs: string, opts: {string:boolean}): Dialog
	a.nvim_buf_set_keymap(self.buf, mode, lhs, rhs, opts)
	return self
end
function Dialog:delKeymap(mode: vim.Mode, lhs: string): Dialog
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
function Dialog:setPrompt(prompt: string, cb: function(string), int: function()): Dialog
	a.nvim_buf_set_option(self.buf, "modifiable", true)
	a.nvim_buf_set_option(self.buf, "buftype", "prompt")
	-- TODO: pester someone about getting api functions for this
	vim.fn.prompt_setprompt(self.buf, prompt or "> ")
	if cb then vim.fn.prompt_setcallback(self.buf, cb) end
	if int then vim.fn.prompt_setinterrupt(self.buf, int) end
	a.nvim_command("startinsert")
	return self
end
function Dialog:unsetPrompt(): Dialog
	a.nvim_buf_set_option(self.buf, "modifiable", false)
	a.nvim_buf_set_option(self.buf, "buftype", "nofile")
	a.nvim_command("stopinsert")
	return self
end
function Dialog:close()
	a.nvim_win_close(self.win, true)
end

return {
	new = new,
	centered = centered,

	Dialog = Dialog,
}

