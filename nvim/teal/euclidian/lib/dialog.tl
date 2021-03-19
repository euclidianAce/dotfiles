
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

local type BufOrId = nvim.Buffer | nvim.Buffer.Id

local function getBuf(maybeBuf: BufOrId): nvim.Buffer
	if not maybeBuf then
		return nvim.createBuf(false, true)
	elseif maybeBuf is nvim.Buffer then
		return maybeBuf
	else
		return nvim.Buffer(maybeBuf)
	end
end

function dialog.new(opts: Dialog.Opts, maybeBuf: BufOrId): Dialog
	local buf <const> = getBuf(maybeBuf)

	buf:setOption("buftype", "nofile")
	buf:setOption("modifiable", false)

	local win <const> = nvim.openWin(buf, true, {
		relative = "editor",
		row = 1, col = 1,
		width = 1, height = 1,
	})
	win:setOption("winblend", 5)

	local ui <const> = nvim.ui()

	local col <const> = opts.col < 0
		and ui.width + opts.col
		or opts.col
	local row <const> = opts.row < 0
		and ui.height + opts.row
		or opts.row

	win:setConfig{
		relative = "editor", style = "minimal", anchor = "NW",
		width = opts.wid, height = opts.hei,
		row = row, col = col,
	}

	return setmetatable({ buf = buf, win = win }, { __index = Dialog })
end

local floor <const>, max <const>, min <const>
	= math.floor, math.max, math.min

local function clamp<T>(n: T, lower: T, upper: T): T
	return min(max(lower, n), upper)
end

function dialog.centeredSize(wid: integer, hei: integer): Dialog.Opts
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

	return {
		col = (ui.width - actualWid) // 2,
		row = (ui.height - actualHei) // 2,
		wid = actualWid,
		hei = actualHei,
	}
end

function dialog.centered(wid: integer, hei: integer, maybeBuf: BufOrId): Dialog
	return dialog.new(dialog.centeredSize(wid, hei), maybeBuf)
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
function Dialog:setLine(num: integer, ln: string): Dialog
	return self:modify(function()
		self.buf:setLines(num, num + 1, false, { ln })
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
function Dialog:getCurrentLine(): string
	return self:getLine((self:getCursor()))
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
	return self:setWin(dialog.centeredSize(width, height))
end
function Dialog:addKeymap(mode: vim.Mode, lhs: string, rhs: string | function, opts: nvim.MapOpts): Dialog
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
function Dialog:fitText(minWid: integer, minHei: integer, maxWid: integer, maxHei: integer): Dialog
	local lines <const> = self.buf:getLines(0, -1, false)
	local line = ""
	for _, ln in ipairs(lines) do
		if #ln > #line then
			line = ln
		end
	end
	local ui <const> = nvim.ui()
	self.win:setHeight(clamp(#lines, minHei or 1, maxHei or ui.height))
	self.win:setWidth(clamp(#line, minWid or 1, maxWid or ui.width))
	return self
end
function Dialog:center(): Dialog
	local ui <const> = nvim.ui()
	local cfg <const> = self.win:getConfig()
	self.win:setConfig{
		relative = "editor",
		col = (ui.width - cfg.width) // 2,
		row = (ui.height - cfg.height) // 2,
		width = cfg.width,
		height = cfg.height,
	}
	return self
end
function Dialog:close()
	self.win:close(true)
end

return dialog
