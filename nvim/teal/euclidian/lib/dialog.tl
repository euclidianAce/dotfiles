
local nvim <const> = require("euclidian.lib.nvim")

local record Dialog
	record Opts
		wid: integer
		hei: integer
		row: integer
		col: integer
	end
	
	buf: nvim.Buffer
	win: nvim.Window
end

local dialog <const> = {
	Dialog = Dialog,
}

function dialog.new(col: integer, row: integer, wid: integer, hei: integer): Dialog
	local buf <const> = nvim.createBuf(false, true)
	buf:setOption("buftype", "nofile")
	buf:setOption("modifiable", false)

	local win <const> = nvim.openWin(buf, true, {
		relative = "editor",
		row = row, col = col,
		width = wid, height = hei,
	})
	win:setOption("winblend", 5)

	local ui <const> = nvim.ui()

	if col < 0 then
		col = ui.width + col
	end
	if row < 0 then
		row = ui.height + row
	end

	win:setConfig{
		relative = "editor", style = "minimal", anchor = "NW",
		width = wid, height = hei,
		row = row, col = col,
	}

	return setmetatable({ buf = buf, win = win }, { __index = Dialog })
end

local floor <const>, max <const>, min <const>
	= math.floor, math.max, math.min

local function clamp<T>(n: T, lower: T, upper: T): T
	return min(max(lower, n), upper)
end

function dialog.centeredSize(wid: integer, hei: integer): integer, integer, integer, integer
	local ui <const> = nvim.ui()

	local actualWid <const> = clamp(
		wid,
		floor(ui.width * .25),
		floor(ui.width * .90)
	)
	local actualHei <const> = clamp(
		hei,
		floor(ui.height * .25),
		floor(ui.height * .90)
	)

	return
		(ui.width - actualWid) // 2, -- col
		(ui.height - actualHei) // 2, -- row
		actualWid, -- wid
		actualHei -- hei
end

function dialog.centered(wid: integer, hei: integer): Dialog
	return dialog.new(dialog.centeredSize(wid, hei))
end

function Dialog:isModifiable(): boolean
	return self.buf:getOption("modifiable")
end
function Dialog:setModifiable(to: boolean)
	self.buf:setOption("modifiable", to)
end
function Dialog:modify(fn: function(Dialog)): Dialog
	local orig <const> = self:isModifiable()
	self:setModifiable(true)
	fn(self)
	self:setModifiable(orig)
	return self
end
function Dialog:setLines(txt: {string}): Dialog
	return self:modify(function()
		self.buf:setLines(0, -1, false, txt)
	end)
end
function Dialog:setText(edits: {{string, integer, integer, integer, integer}}): Dialog
	-- edit: {text, start_row, start_col, end_row, end_col}
	return self:modify(function()
		for _, edit in ipairs(edits) do
			self.buf:setText(edit[2], edit[3], edit[4], edit[5], {edit[1]})
		end
	end)
end
function Dialog:setCursor(row: integer, col: integer): Dialog
	self.win:setCursor{row, col}
	return self
end
function Dialog:getCursor(): integer, integer
	local pos <const> = self.win:getCursor()
	return pos[1], pos[2]
end
function Dialog:getLine(n: integer): string
	return self.buf:getLines(n - 1, n, false)[1]
end
function Dialog:getLines(min: integer, max: integer): {string}
	return self.buf:getLines(min or 0, max or -1, false)
end
function Dialog:setWin(o: Dialog.Opts): Dialog
	self.win:setConfig{
		relative = "editor",
		row = assert(o.row, "no row"), col = assert(o.col, "no col"),
		width = assert(o.wid, "no wid"), height = assert(o.hei, "no hei"),
	}
	return self
end
function Dialog:center(width: integer, height: integer): Dialog
	local col <const>, row <const>, wid <const>, hei <const> = dialog.centeredSize(width, height)
	self:setWin{ col = col, row = row, wid = wid, hei = hei }
	return self
end
function Dialog:addKeymap(mode: vim.Mode, lhs: string, rhs: string, opts: nvim.MapOpts): Dialog
	self.buf:setKeymap(mode, lhs, rhs, opts)
	return self
end
function Dialog:delKeymap(mode: vim.Mode, lhs: string): Dialog
	self.buf:delKeymap(mode, lhs)
	return self
end
function Dialog:setPrompt(prompt: string, cb: function(string), int: function()): Dialog
	self.buf:setOption("modifiable", true)
	self.buf:setOption("buftype", "prompt")
	-- TODO: pester someone about getting api functions for this
	vim.fn.prompt_setprompt(self.buf.id, prompt or "> ")
	if cb then vim.fn.prompt_setcallback(self.buf.id, cb) end
	if int then vim.fn.prompt_setinterrupt(self.buf.id, int) end
	nvim.command("startinsert")
	return self
end
function Dialog:unsetPrompt(): Dialog
	self.buf:setOption("modifiable", false)
	self.buf:setOption("buftype", "nofile")
	nvim.command("stopinsert")
	return self
end
function Dialog:close()
	self.win:close(true)
end

return dialog
