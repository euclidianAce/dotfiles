
local nvim <const> = require("euclidian.lib.nvim")

local record TextRegion
	record Position
		line: integer
		char: integer
	end
	start: Position
	finish: Position

	nlines: integer
	nchars: integer
end

local record Dialog
	record Opts
		wid: integer
		hei: integer
		row: integer
		col: integer

		notMinimal: boolean
		interactive: boolean

		border: { string | {string, string} }
	end
	
	buf: nvim.Buffer
	win: nvim.Window

	regions: {TextRegion} -- sorted by location
end

local dialog <const> = {
	Dialog = Dialog,
	TextRegion = TextRegion,
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

local defaultBorderHighlight = "Normal"
local defaultBorder <const> = {
	{"╭", defaultBorderHighlight},
	{"─", defaultBorderHighlight},
	{"╮", defaultBorderHighlight},
	{"│", defaultBorderHighlight},
	{"╯", defaultBorderHighlight},
	{"─", defaultBorderHighlight},
	{"╰", defaultBorderHighlight},
	{"│", defaultBorderHighlight},
}

function dialog.optsToWinConfig(opts: Dialog.Opts): nvim.Window.Config
	local col = assert(opts.col, "no col")
	local row = assert(opts.row, "no row")

	local ui: nvim.UI
	if col < 0 then
		ui = nvim.ui()
		col = ui.width + opts.col
	end
	if row < 0 then
		ui = ui or nvim.ui()
		row = ui.height + opts.row
	end

	return {
		relative = "editor",
		border = opts.border or defaultBorder,
		row = row,
		col = col,
		width = assert(opts.wid, "no wid"),
		height = assert(opts.hei, "no hei"),
		style = not opts.notMinimal and "minimal" or nil,

		focusable = opts.interactive,
	}
end

function dialog.new(opts: Dialog.Opts, maybeBuf: BufOrId): Dialog
	local buf <const> = getBuf(maybeBuf)

	if buf:getOption("buftype") == "" then
		buf:setOption("buftype", "nofile")
	end
	buf:setOption("modifiable", false)

	local win <const> = nvim.openWin(
		buf,
		opts.interactive,
		dialog.optsToWinConfig(opts)
	)

	-- win:setOption("winblend", 5)
	win:setOption("winhl", "Normal:Normal")

	return setmetatable({ buf = buf, win = win, regions = {} }, { __index = Dialog })
end

local floor <const>, max <const>, min <const>
	= math.floor, math.max, math.min

local function clamp<T>(n: number, lower: T, upper: T): T
	return min(max(lower, n), upper) as T
end

-- n < 0 => wrap around from base
-- n < 1 => percentage of base
-- else  => clamp n between 1 and base
local function convertNum(n: number, base: integer): integer
	if n < 0 then
		return floor(base + n)
	elseif n < 1 then
		return floor(base * n)
	else
		return clamp(n, 1, base)
	end
end

function dialog.centeredOpts(wid: number, hei: number): Dialog.Opts
	local ui <const> = nvim.ui()

	local actualWid <const> = convertNum(wid, ui.width)
	local actualHei <const> = convertNum(hei, ui.height)

	return {
		col = (ui.width - actualWid) // 2,
		row = (ui.height - actualHei) // 2,
		wid = actualWid,
		hei = actualHei,
	}
end

function dialog.optsWithDefaults(overrides: Dialog.Opts): Dialog.Opts
	return {
		wid = overrides and overrides.wid or math.huge,
		hei = overrides and overrides.hei or math.huge,
		row = overrides and overrides.row or 0,
		col = overrides and overrides.col or 0,
		border = vim.deepcopy(defaultBorder),
	}
end

function dialog.centered(wid: number, hei: number, opts: Dialog.Opts, maybeBuf: BufOrId): Dialog
	local copts <const> = dialog.centeredOpts(wid, hei) as table
	for k, v in pairs(opts as table) do
		if not copts[k] then
			copts[k] = v
		end
	end
	return dialog.new(copts as Dialog.Opts, maybeBuf)
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
function Dialog:setWinConfig(c: nvim.Window.Config): Dialog
	local orig <const> = self.win:getConfig() as table
	local new <const>: table = {}
	for k, v in pairs(orig) do
		new[k] = (c as table)[k] or v
	end
	self.win:setConfig(new as nvim.Window.Config)
	return self
end
function Dialog:moveAbsolute(row: integer, col: integer): Dialog
	local c <const> = self.win:getConfig()
	c.row = row
	c.col = col
	self.win:setConfig(c)
	return self
end
function Dialog:moveRelative(drow: integer, dcol: integer): Dialog
	local c <const> = self.win:getConfig()
	c.row = c.row + drow
	c.col = c.col + dcol
	self.win:setConfig(c)
	return self
end
function Dialog:setOpts(opts: Dialog.Opts): Dialog
	opts = dialog.optsWithDefaults(opts)
	return self:setWinConfig(dialog.optsToWinConfig(opts))
end
function Dialog:center(width: integer, height: integer): Dialog
	return self:setOpts(dialog.centeredOpts(width, height))
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
function Dialog:fitTextPadded(colPad: integer, rowPad: integer, minWid: integer, minHei: integer, maxWid: integer, maxHei: integer): Dialog
	local lines <const> = self.buf:getLines(0, -1, false)
	local line = ""
	for _, ln in ipairs(lines) do
		if #ln > #line then
			line = ln
		end
	end
	local ui <const> = nvim.ui()
	self.win:setHeight(clamp(
		#lines + (rowPad or 0),
		minHei or 1,
		maxHei or ui.height
	))
	self.win:setWidth(clamp(
		#line + (colPad or 0),
		minWid or 1,
		maxWid or ui.width
	))
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
function Dialog:centerHorizontal(): Dialog
	local ui <const> = nvim.ui()
	local cfg <const> = self.win:getConfig()
	self.win:setConfig{
		relative = "editor",
		col = (ui.width - cfg.width) // 2,
		row = cfg.row,
		width = cfg.width,
		height = cfg.height,
	}
	return self
end
function Dialog:centerVertical(): Dialog
	local ui <const> = nvim.ui()
	local cfg <const> = self.win:getConfig()
	self.win:setConfig{
		relative = "editor",
		col = cfg.col,
		row = (ui.height - cfg.height) // 2,
		width = cfg.width,
		height = cfg.height,
	}
	return self
end
function Dialog:close()
	self.win:close(true)
end

local function cmpPos(a: TextRegion.Position, b: TextRegion.Position): boolean
	return a.line == b.line
		and a.char < b.char
		or a.line < b.line
end

function Dialog:claimRegion(start: TextRegion.Position, nlines: integer, nchars: integer): TextRegion
	local r <const> = setmetatable({
		start  = { line = start.line, char = start.char },
		finish = {
			line = start.line + nlines,
			char = nlines > 0
				and nchars
				or start.char + nchars,
		},
		nlines = nlines,
		nchars = nchars,
	} as TextRegion, {
		__index = TextRegion,
		parent = self,
	} as metatable<TextRegion>)
	for i = 1, #self.regions - 1 do
		local cur <const>, nxt <const> = self.regions[i], self.regions[i+1]
		if cmpPos(cur.finish, r.start) and cmpPos(r.finish, nxt.start) then
			table.insert(self.regions, i, r)
			return r
		end
	end
	table.insert(self.regions, r)
	return r
end

local record TextRegionMt
	__index: TextRegion
	parent: Dialog
	unclaimed: boolean
end

local function getmt(tr: TextRegion): TextRegionMt
	return getmetatable(tr) as TextRegionMt
end

local function pad(s: string, len: integer): string
	return s .. (" "):rep(len - #s)
end

function TextRegion:set(s: string, clear: boolean): boolean
	local d <const> = getmt(self).parent
	local buf <const> = d.buf
	local inputLns <const> = { unpack(vim.split(s, "\n"), 1, self.nlines + 1) } -- trim excess lines

	d:modify(function()
		-- Region is exactly one line
		if self.nlines == 1 and self.start.char == 0 then
			buf:setLines(
				self.start.line,
				self.finish.line + 1,
				false,
				inputLns
			)
			return
		end

		-- Region starts in the middle of the first line
		if self.start.char ~= 0 and self.nlines == 0 then
			-- within single line, only replace the region
			local txt = inputLns[1]

			local sRow <const> = self.start.line
			local sCol <const> = self.start.char

			local nchars <const> = math.min(#txt, self.nchars)
			local eCol: integer
			if clear then
				txt = pad(txt, self.nchars)
				eCol = sCol + self.nchars
			else
				txt = txt:sub(1, nchars)
				eCol = sCol + nchars
			end

			buf:setText(
				sRow, sCol,
				sRow, eCol,
				{ txt }
			)

			return
		end

		local currentLines <const> = buf:getLines(self.start.line, self.finish.line + 1, false)
		if self.nlines > 0 then
			currentLines[1] = currentLines[1]:sub(1, self.start.char) .. inputLns[1]
		end

		local batchIncludesLastLine = true
		-- last line stops in the middle
		if self.nlines > 1 and self.nchars > 0 then
			batchIncludesLastLine = false
			local txt = table.remove(currentLines)

			local nchars <const> = math.min(#txt, self.nchars)
			local eCol: integer
			if clear then
				txt = pad(txt, self.nchars)
				eCol = self.nchars
			else
				txt = txt:sub(1, nchars)
				eCol = nchars
			end

			buf:setText(
				self.finish.line, 0,
				self.finish.line, eCol,
				{ txt }
			)
		end

		buf:setLines(
			self.start.line,
			self.finish.line + (batchIncludesLastLine and 1 or 0),
			false,
			currentLines
		)
	end)
end

for name, fn in pairs(TextRegion as {string:function}) do
	(TextRegion as {string:function})[name] = function(self: TextRegion, ...: any): any...
		if getmt(self).unclaimed then
			error("TextRegion has already been unclaimed", 2)
		end
		return fn(self, ...)
	end
end

function TextRegion:unclaim()
	local mt <const> = getmt(self)
	if mt.unclaimed then return end
	mt.unclaimed = true
	local d <const> = mt.parent
	for i, v in ipairs(d.regions) do
		if self == v then
			table.remove(d.regions, i)
			return
		end
	end
end

return dialog
