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
		zindex: integer

		notMinimal: boolean
		interactive: boolean
		hidden: boolean
		ephemeral: boolean

		winhl: {string:string}

		record Center
			horizontal: boolean
			vertical: boolean
		end
		centered: boolean | Center

		border: nvim.Window.Config.Border
	end

	regions: {TextRegion} -- sorted by location
end

local bufs <const>: {Dialog:nvim.Buffer} = setmetatable({}, { __mode = "k", __index = function(): nvim.Buffer return nvim.Buffer(-1) end })
local wins <const>: {Dialog:nvim.Window} = setmetatable({}, { __mode = "k", __index = function(): nvim.Window return nvim.Window(-1) end })
local links <const>: {Dialog:{Dialog}} = setmetatable({}, { __mode = "k", __index = function(self: {Dialog:{Dialog}}, k: Dialog): {Dialog}
	local t = {}
	rawset(self, k, t)
	return t
end})
local origOpts <const>: {Dialog:Dialog.Opts} = setmetatable({}, { __mode = "k" })

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

local function defaultWinHl(): {string:string}
	return { Normal = "Normal", NormalFloat = "Normal" }
end

local function copyWinHl(m: {string:string}): {string:string}
	local copy = {}
	if m then
		for k, v in pairs(m) do
			copy[k] = v
		end
	else
		return defaultWinHl()
	end
	return copy
end

local function copyOpts(o: Dialog.Opts): Dialog.Opts
	-- TODO: We should totally steal zig's `inline for` for teal
	return {
		wid = o.wid,
		hei = o.hei,
		row = o.row,
		col = o.col,
		zindex = o.zindex,
		notMinimal = o.notMinimal,
		interactive = o.interactive,
		hidden = o.hidden,
		border = o.border,
		centered = copyCenterOpts(o.centered),
		winhl = copyWinHl(o.winhl),
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
		if not maybeBuf:isValid() then
			return nvim.createBuf(false, true)
		end
		return maybeBuf
	else
		return nvim.Buffer(maybeBuf)
	end
end

local defaultBorderHighlight <const> = "Delimiter"
-- local defaultBorder <const>: {{string, string}} = {
	-- { "╭", defaultBorderHighlight },
	-- { "─", defaultBorderHighlight },
	-- { "╮", defaultBorderHighlight },
	-- { "│", defaultBorderHighlight },
	-- { "╯", defaultBorderHighlight },
	-- { "─", defaultBorderHighlight },
	-- { "╰", defaultBorderHighlight },
	-- { "│", defaultBorderHighlight },
-- }

local defaultBorder <const>: {{string, string}} = {
	{ "🭽", defaultBorderHighlight }, { "▔", defaultBorderHighlight },
	{ "🭾", defaultBorderHighlight }, { "🭵", defaultBorderHighlight },
	{ "🭿", defaultBorderHighlight }, { "▁", defaultBorderHighlight },
	{ "🭼", defaultBorderHighlight }, { "▏", defaultBorderHighlight },
}

function dialog.getDefaultBorder(): {{string, string}}
	return vim.deepcopy(defaultBorder)
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
		return floor(clamp(n, 1, base))
	end
end

function dialog.optsToWinConfig(opts: Dialog.Opts): nvim.Window.Config
	local cfg <const>: nvim.Window.Config = {
		relative = "editor",
		style = not opts.notMinimal and "minimal" or nil,
		border = opts.border or defaultBorder,
		focusable = opts.interactive,
		zindex = opts.zindex,
	}
	local ui <const> = nvim.ui()

	local center <const> = copyCenterOpts(opts.centered)

	if center.horizontal then
		cfg.width = convertNum(
			assert(opts.wid, "horizontally centered dialogs require a 'wid' field"),
			ui.width
		)
		cfg.col = (ui.width - cfg.width) // 2
	else
		cfg.col = convertNum(assert(opts.col, "non-centered dialogs require a 'col' field"), ui.width)
		cfg.width = convertNum(assert(opts.wid, "non-centered dialogs require a 'wid' field"), ui.width)
	end

	if center.vertical then
		cfg.height = convertNum(
			assert(opts.hei, "vertically centered dialogs require a 'hei' field"),
			ui.height
		)
		cfg.row = (ui.height - cfg.height) // 2
	else
		cfg.row = convertNum(assert(opts.row, "non-centered dialogs require a 'row' field"), ui.height)
		cfg.height = convertNum(assert(opts.hei, "non-centered dialogs require a 'hei' field"), ui.height)
	end

	return cfg
end

local function setupBuf(opts: Dialog.Opts, maybeBuf: BufOrId): nvim.Buffer
	local buf <const> = getBuf(maybeBuf)

	if buf:getOption("buftype") == "" then
		buf:setOption("buftype", "nofile")
	end

	buf:setOption("modifiable", false)
	if opts.ephemeral then
		buf:setOption("bufhidden", "wipe")
	end

	return buf
end

local function setupWin(opts: Dialog.Opts, buf: nvim.Buffer): nvim.Window
	if opts.hidden then
		return nvim.Window(-1)
	end
	local cfg <const> = dialog.optsToWinConfig(opts)
	local win <const> = nvim.openWin(buf, opts.interactive, cfg)

	if win:isValid() then
		local strs <const> = {}
		for k, v in pairs(opts.winhl or defaultWinHl()) do
			table.insert(strs, k .. ":" .. v)
		end
		win:setOption("winhighlight", table.concat(strs, ","))
	end

	return win
end

function dialog.new(opts: Dialog.Opts, maybeBuf: BufOrId): Dialog
	opts = opts or {}
	local buf <const> = setupBuf(opts, maybeBuf)
	local win <const> = setupWin(opts, buf)

	local d <const> = setmetatable({ regions = {} }, { __index = Dialog })

	bufs[d] = buf
	wins[d] = win
	origOpts[d] = copyOpts(opts)

	return d
end

function dialog.fromWindow(win: nvim.Window): Dialog
	local d <const> = setmetatable({ regions = {} }, { __index = Dialog })
	bufs[d] = nvim.Buffer(win:getBuf())
	wins[d] = win
	return d
end

function Dialog:setBuffer(b: nvim.Buffer): Dialog
	bufs[self] = b
	return self
end

-- TODO: should probably keep linked dialogs in a set rather than a list
function Dialog:link(...: Dialog): Dialog
	local ls <const> = links[self]
	for i = 1, select("#", ...) do
		local d <const> = select(i, ...)
		if d then
			table.insert(ls, d)
		end
	end
	return self
end
function Dialog:unlink(...: Dialog): Dialog
	local ls <const> = links[self]
	for argI = 1, select("#", ...) do
		local d <const> = select(argI, ...)
		for i, v in ipairs(ls) do
			if v == d then
				table.remove(ls, i)
			end
		end
	end
end

function Dialog:origOpts(): Dialog.Opts
	return copyOpts(origOpts[self])
end
function Dialog:buf(): nvim.Buffer
	return bufs[self]
end
function Dialog:ensureBuf(): nvim.Buffer -- always returns a valid buffer
	if bufs[self]:isValid() then
		return bufs[self]
	end
	bufs[self] = setupBuf(self:origOpts())
	assert(bufs[self]:isValid(), "Dialog:ensureBuf() produced an invalid buffer")
	return bufs[self]
end
function Dialog:win(): nvim.Window
	return wins[self]
end
function Dialog:show(dontSwitch: boolean): Dialog
	if wins[self]:isValid() then
		-- already showing
		return self
	end

	if not self:buf():isValid() then
		bufs[self] = setupBuf(origOpts[self])
	end

	local opts <const> = copyOpts(origOpts[self])
	opts.hidden = false
	wins[self] = setupWin(opts, self:ensureBuf())
	if not dontSwitch then
		vim.api.nvim_set_current_win(wins[self].id);
	end

	return self
end
function Dialog:ensureWin(): nvim.Window
	-- implicitly ensures the buffer as well
	self:show(true)
	assert(wins[self]:isValid(), "Dialog:ensureWin() produced an invalid window")
	return wins[self]
end

function Dialog:isModifiable(): boolean
	return self:buf():getOption("modifiable")
end
function Dialog:setModifiable(to: boolean)
	self:buf():setOption("modifiable", to or false)
end
function Dialog:modify(fn: function(Dialog)): Dialog
	vim.schedule(function()
		local orig <const> = self:isModifiable()
		self:setModifiable(true)
		fn(self)
		self:setModifiable(orig)
	end)
	return self
end
function Dialog:setLines(txt: {string}): Dialog
	return self:modify(function()
		self:buf():setLines(0, -1, false, txt)
	end)
end
function Dialog:appendLines(txt: {string}): Dialog
	return self:modify(function()
		bufs[self]:setLines(-1, -1, false, txt)
	end)
end
function Dialog:setLine(num: integer, ln: string): Dialog
	return self:modify(function()
		bufs[self]:setLines(num, num + 1, false, { ln })
	end)
end
function Dialog:setText(edits: {{string, integer, integer, integer, integer}}): Dialog
	-- edit: {text, start_row, start_col, end_row, end_col}
	return self:modify(function()
		local b <const> = bufs[self]
		for _, edit in ipairs(edits) do
			b:setText(edit[2], edit[3], edit[4], edit[5], {edit[1]})
		end
	end)
end
function Dialog:setCursor(row: integer, col: integer): Dialog
	self:win():setCursor{row or 1, col or 0}
	return self
end
function Dialog:getCursor(): integer, integer
	local pos <const> = self:win():getCursor()
	return pos[1], pos[2]
end
function Dialog:getRow(): integer
	local cfg <const> = self:win():getConfig()
	return (cfg.row as {boolean:integer})[false]
end
function Dialog:getColumn(): integer
	local cfg <const> = self:win():getConfig()
	return (cfg.col as {boolean:integer})[false]
end
function Dialog:getLine(n: integer): string
	return self:buf():getLines(n - 1, n, false)[1]
end
function Dialog:getCurrentLine(): string
	return self:getLine((self:getCursor()))
end
function Dialog:getLines(minimum: integer, maximum: integer): {string}
	return self:buf():getLines(minimum or 0, maximum or -1, false)
end
function Dialog:setWinConfig(c: nvim.Window.Config): Dialog
	local win <const> = self:win()
	local orig <const> = win:getConfig() as table
	local new <const>: table = {}
	for k, v in pairs(orig) do
		new[k] = (c as table)[k] or v
	end
	win:setConfig(new as nvim.Window.Config)
	return self
end
local function relativePosition(wina: nvim.Window.Config, winb: nvim.Window.Config): integer, integer
	local row <const> = (wina.row as {boolean:integer})[false] - (winb.row as {boolean:integer})[false]
	local col <const> = (wina.col as {boolean:integer})[false] - (winb.col as {boolean:integer})[false]
	return row, col
end
function Dialog:moveAbsolute(row: integer, col: integer): Dialog
	local win <const> = self:win()
	local cfg <const> = win:getConfig()
	for _, d in ipairs(links[self]) do
		local r <const>, c <const> = relativePosition(cfg, d:win():getConfig())
		d:moveAbsolute(row + r, col - c)
	end
	cfg.row = row
	cfg.col = col
	win:setConfig(cfg)
	return self
end
function Dialog:moveRelative(drow: integer, dcol: integer): Dialog
	local win <const> = self:win()
	local c <const> = win:getConfig()
	c.row = (c.row as {boolean:integer})[false] + drow
	c.col = (c.col as {boolean:integer})[false] + dcol
	win:setConfig(c)
	return self
end
function Dialog:setOpts(opts: Dialog.Opts): Dialog
	return self:setWinConfig(dialog.optsToWinConfig(opts))
end
function Dialog:addKeymap(mode: vim.Mode, lhs: string, rhs: string | function, opts: vim.keymap.Opts): Dialog
	self:buf():setKeymap(mode, lhs, rhs, opts)
	return self
end
function Dialog:delKeymap(mode: vim.Mode, lhs: string): Dialog
	self:buf():delKeymap(mode, lhs)
	return self
end
function Dialog:setPrompt(prompt: string, cb: function(string), int: function()): Dialog
	local buf <const> = self:buf()
	buf:setOption("modifiable", true)
	buf:setOption("buftype", "prompt")
	-- TODO: pester someone about getting api functions for this
	vim.fn.prompt_setprompt(buf.id, prompt or "> ")
	if cb then vim.fn.prompt_setcallback(buf.id, cb) end
	if int then vim.fn.prompt_setinterrupt(buf.id, int) end
	nvim.command("startinsert")
	return self
end
function Dialog:unsetPrompt(): Dialog
	local buf <const> = self:buf()
	buf:setOption("modifiable", false)
	buf:setOption("buftype", "nofile")
	nvim.command("stopinsert")
	return self
end
function Dialog:fitText(minWid: integer, minHei: integer, maxWid: integer, maxHei: integer): Dialog
	local lines <const> = self:buf():getLines(0, -1, false)
	local longest = 0
	for _, ln in ipairs(lines) do
		local len <const> = #ln
		if longest < len then
			longest = len
		end
	end
	local ui <const> = nvim.ui()
	local win <const> = self:win()
	win:setHeight(clamp(#lines, minHei or 1, maxHei or ui.height))
	win:setWidth(clamp(longest, minWid or 1, maxWid or ui.width))
	return self
end
function Dialog:setWinSize(width: integer, height: integer): Dialog
	local win <const> = self:win()
	local ui <const> = nvim.ui()
	if height then win:setHeight(clamp(height, 1, ui.height)) end
	if width then win:setWidth(clamp(width, 1, ui.width)) end
	return self
end
function Dialog:fitTextPadded(colPad: integer, rowPad: integer, minWid: integer, minHei: integer, maxWid: integer, maxHei: integer): Dialog
	local lines <const> = self:buf():getLines(0, -1, false)
	local line = ""
	for _, ln in ipairs(lines) do
		if #ln > #line then
			line = ln
		end
	end
	local ui <const> = nvim.ui()
	local win <const> = self:win()
	win:setHeight(clamp(
		#lines + (rowPad or 0),
		minHei or 1,
		maxHei or ui.height
	))
	win:setWidth(clamp(
		#line + (colPad or 0),
		minWid or 1,
		maxWid or ui.width
	))
	return self
end
function Dialog:center(): Dialog
	local ui <const> = nvim.ui()
	local win <const> = self:win()
	local cfg <const> = win:getConfig()
	win:setConfig{
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
	local win <const> = self:win()
	local cfg <const> = win:getConfig()
	win:setConfig{
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
	local win <const> = self:win()
	local cfg <const> = win:getConfig()
	win:setConfig{
		relative = "editor",
		col = cfg.col,
		row = (ui.height - cfg.height) // 2,
		width = cfg.width,
		height = cfg.height,
	}
	return self
end
function Dialog:hide(): Dialog
	local w <const> = self:win()
	if not w:isValid() then
		return self
	end
	w:hide()
	return self
end
function Dialog:focus(): Dialog
	nvim.api.setCurrentWin(self:win().id)
	return self
end
function Dialog:close()
	local w <const> = self:win()
	if w:isValid() then
		w:close(true)
	end
end

local linkedFns <const>: {string:boolean} = {
	hide = true,
	close = true,
	show = true,
	moveRelative = true,
}
local _Dialog <const> = Dialog as {string:function(...: any): any...}
for k in pairs(linkedFns) do
	local oldFn <const> = _Dialog[k]
	_Dialog[k] = function(self: Dialog, ...: any): any...
		for _, d in ipairs(links[self]) do
			oldFn(d, ...)
		end
		return oldFn(self, ...)
	end
end

local function cmpPos(lhs: TextRegion.Position, rhs: TextRegion.Position): boolean
	return lhs.line == rhs.line
		and lhs.char < rhs.char
		or lhs.line < rhs.line
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
	local buf <const> = d:buf()
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
			currentLines[1] = (currentLines[1] or ""):sub(1, self.start.char) .. inputLns[1]
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
