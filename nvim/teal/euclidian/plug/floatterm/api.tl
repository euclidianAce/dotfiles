local nvim <const> = require("euclidian.lib.nvim")
local terminal <const> = require("euclidian.lib.terminal")
local dialog <const> = require("euclidian.lib.dialog")

local type Terminal = terminal.Terminal
local type Dialog = dialog.Dialog

local record FloatTerm
	terminal: Terminal
	dialog: Dialog
	savedConfig: nvim.Window.Config

	type KeyMap = {vim.Mode | {vim.Mode}, string, vim.keymap.SetOptions}

	record Mappings
		-- TODO: allow multiple mappings for each action
		show: KeyMap
		hide: KeyMap
		toggle: KeyMap
	end
	mappings: Mappings

	show: function(FloatTerm)
	hide: function(FloatTerm)
	toggle: function(FloatTerm)
end

local function setMap(map: FloatTerm.KeyMap, func: function()) vim.keymap.set(map[1], map[2], func, map[3]) end
local function delMap(map: FloatTerm.KeyMap) vim.keymap.del(map[1], map[2], { buffer = (map[3] or {}).buffer }) end

local floatterm <const> = {
	FloatTerm = FloatTerm,
}

local function copyKeymaps(map: FloatTerm.Mappings): FloatTerm.Mappings
	return {
		show = map.show and { unpack(map.show as {any}, 1, 3) },
		hide = map.hide and { unpack(map.hide as {any}, 1, 3) },
		toggle = map.toggle and { unpack(map.toggle as {any}, 1, 3) },
	} as FloatTerm.Mappings
end

function floatterm.new(
	dialogOpts: Dialog.Opts,
	cmd: string | {string},
	termOpts: Terminal.OpenOpts,
	mappings: FloatTerm.Mappings
): FloatTerm
	local buf <const> = nvim.createBuf(false, true)
	-- TODO: don't modify args
	dialogOpts.hidden = true
	dialogOpts.interactive = true
	local t <const>: FloatTerm = setmetatable({
		dialog = dialog.new(dialogOpts, buf),
		terminal = terminal.create(cmd, termOpts, buf),
		mappings = mappings and copyKeymaps(mappings),
	}, { __index = FloatTerm })
	if t.mappings and t.mappings.toggle then
		setMap(
			t.mappings.toggle,
			function() t:toggle() end
		)
	end
	return t
end

local cache <const>: {nvim.Window.Id:FloatTerm} = setmetatable({}, { __mode = "kv" })

-- returns nil if window isn't a FloatTerm
function floatterm.fromWindow(win: nvim.Window): FloatTerm
	local id = win and win.id or nvim.api.getCurrentWin()
	return cache[id]
end

function FloatTerm:show()
	if self.dialog:win():isValid() then
		return
	end
	self.terminal:ensureOpen()
	self.dialog:setBuffer(self.terminal.buf)
	self.dialog:show()
	if self.savedConfig then
		self.dialog:win():setConfig(self.savedConfig)
		self.savedConfig = nil
	end
	if self.mappings then
		if self.mappings.hide then
			setMap(
				self.mappings.hide,
				function() self:hide() end
			)
		end
		if self.mappings.show then
			delMap(self.mappings.show)
		end
	end
	cache[self.dialog:win().id] = self
end

function FloatTerm:hide()
	local win <const> = self.dialog:win()
	if not win:isValid() then return end
	cache[win.id] = nil
	self.savedConfig = win:getConfig()
	self.dialog:hide()
	if self.mappings then
		if self.mappings.show then
			setMap(
				self.mappings.show,
				function() self:show() end
			)
		end
		if self.mappings.hide then
			delMap(self.mappings.hide)
		end
	end
end

function FloatTerm:toggle()
	if self.dialog:win():isValid() then
		self:hide()
	else
		self:show()
	end
end

function FloatTerm:close()
	local win <const> = self.dialog:win()
	if win:isValid() then
		cache[win.id] = nil
	end
	self.dialog:close()
	self.terminal:close()
end

return floatterm
