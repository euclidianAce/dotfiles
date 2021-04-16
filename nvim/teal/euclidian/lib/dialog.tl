
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
	-- consider Opts to be lazily evaluated
	-- "evaluation" meaning being turning into a window config
	record Opts
		wid: number
		hei: number
		row: number
		col: number

		notMinimal: boolean
		interactive: boolean
		hidden: boolean
		
		record Center
			horizontal: boolean
			vertical: boolean
		end
		centered: boolean | Center

		border: nvim.Window.Config.Border
	end
	
	buf: nvim.Buffer
	win: nvim.Window

	regions: {TextRegion} -- sorted by location

	_origOpts: Opts
end

local function copyCenterOpts(o: boolean | Dialog.Opts.Center): Dialog.Opts.Center
	local cpy <const>: Dialog.Opts.Center = {}
	if not o then
		cpy.vertical = false
		cpy.horizontal = false
	elseif o is boolean then
		cpy.vertical = true
		cpy.horizontal = true
	else
		cpy.vertical = o.vertical
		cpy.horizontal = o.horizontal
	end
	return cpy
end

local function copyOpts(o: Dialog.Opts): Dialog.Opts
	-- TODO: We should totally steal zig's `inline for` for teal
	return {
		wid = o.wid,
		hei = o.hei,
		row = o.row,
		col = o.col,
		notMinimal = o.notMinimal,
		interactive = o.interactive,
		hidden = o.hidden,
		border = o.border,
		centered = copyCenterOpts(o.centered),
	}
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
local defaultBorder <const>: nvim.Window.Config.Border = {
	{"╭", defaultBorderHighlight},
	{"─", defaultBorderHighlight},
	{"╮", defaultBorderHighlight},
	{"│", defaultBorderHighlight},
	{"╯", defaultBorderHighlight},
	{"─", defaultBorderHighlight},
	{"╰", defaultBorderHighlight},
	{"│", defaultBorderHighlight},
}

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
		return floor(clamp(n, 1, base))
	end
end

function dialog.optsToWinConfig(opts: Dialog.Opts): nvim.Window.Config
	local cfg <const>: nvim.Window.Config = {
		relative = "editor",
		style = not opts.notMinimal and "minimal" or nil,
		border = opts.border or defaultBorder,
		focusable = opts.interactive,
	}
	local ui <const> = nvim.ui()

	local center <const> = copyCenterOpts(opts.centered)

	if center.horizontal then
		cfg.width = convertNum(
			assert(opts.wid, "centered dialogs require a 'wid' field"),
			ui.width
		)
		cfg.col = (ui.width - cfg.width) // 2
	else
		cfg.col = convertNum(assert(opts.col, "non-centered dialogs require a 'col' field"), ui.width)
		cfg.width = convertNum(assert(opts.wid, "non-centered dialogs require a 'wid' field"), ui.width)
	end

	if center.vertical then
		cfg.height = convertNum(
			assert(opts.hei, "centered dialogs require a 'hei' field"),
			ui.height
		)
		cfg.row = (ui.height - cfg.height) // 2
	else
		cfg.row = convertNum(assert(opts.row, "non-centered dialogs require a 'row' field"), ui.height)
		cfg.height = convertNum(assert(opts.hei, "non-centered dialogs require a 'hei' field"), ui.height)
	end

	return cfg
end

function dialog.new(opts: Dialog.Opts, maybeBuf: BufOrId): Dialog
	local buf <const> = getBuf(maybeBuf)

	if buf:getOption("buftype") == "" then
		buf:setOption("buftype", "nofile")
	end
	buf:setOption("modifiable", false)

	local cfg <const> = dialog.optsToWinConfig(opts)
	local win <const> = opts and not opts.hidden and nvim.openWin(
		buf,
		opts.interactive,
		cfg
	) or { isValid = function(): boolean return false end }

	if win:isValid() then
		win:setOption("winhighlight", "Normal:Normal,NormalFloat:Normal")
	end

	return setmetatable({
		buf = buf,
		win = win,
		regions = {},
		_origOpts = copyOpts(opts),
	}, { __index = Dialog })
end

function Dialog:show(dontSwitch: boolean, cfg: nvim.Window.Config): Dialog
	if self.win:isValid() then
		-- already showing
		return self
	end

	self.win = nvim.openWin(
		self.buf,
		not dontSwitch,
		cfg or (self._origOpts and dialog.optsToWinConfig(self._origOpts)) or {}
	)

	self.win:setOption("winhighlight", "Normal:Normal,NormalFloat:Normal")
	return self
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
function Dialog:appendLines(txt: {string}): Dialog
	return self:modify(function()
		self.buf:setLines(-1, -1, false, txt)
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
	return self:setWinConfig(dialog.optsToWinConfig(opts))
end
function Dialog:center(width: integer, height: integer): Dialog
	assert(false and width and height)
	-- return self:setOpts(dialog.centeredOpts(width, height))
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
function Dialog:hide(): Dialog
	self.win:hide()
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
