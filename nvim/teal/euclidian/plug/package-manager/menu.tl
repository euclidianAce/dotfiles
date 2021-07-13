
local dialog <const> = require("euclidian.lib.dialog")
-- local nvim <const> = require("euclidian.lib.nvim")
local z <const> = require("euclidian.lib.async.zig")

-- local type NilFrame = z.Frame<nil>

local record Menu
	enum Kind
		"accordion"
	end
	kind: Kind

	type Item = string | {string, Item}
	items: {Item}
end

local menu <const> = {
	Menu = Menu,
}

function menu.new(kind: Menu.Kind): Menu
	return setmetatable({ kind = kind, items = {} }, { __index = Menu })
end

function Menu:add(item: Menu.Item): Menu
	table.insert(self.items, item)
	return self
end

function Menu:step(opts: dialog.Dialog.Opts): function({Menu.Item}): string
	local d <const> = dialog.new(opts)
	-- local buf <const> = d:ensureBuf()
	local function waitForKey(...: string): string
		local keys <const> = {...}
		local function delKeymaps()
			for _, key in ipairs(keys) do
				d:delKeymap("n", key)
			end
		end
		local me <const> = assert(z.currentFrame(), "attempt to waitForKey not in a coroutine")
		local pressed: string
		z.suspend(vim.schedule_wrap(function()
			local keyopts <const> = { noremap = true, silent = true }
			for _, key in ipairs(keys) do
				d:addKeymap("n", key, function()
					pressed = key
					delKeymaps()
					z.resume(me)
				end, keyopts)
			end
		end))
		return pressed
	end

	assert(self.kind == "accordion")

	local record State
		enabled: boolean
		line: integer
	end
	local states <const>: {Menu.Item:State} = {}
	local function appendItem(lines: {string}, item: Menu.Item, indent: integer)
		local len <const> = #lines + 1
		if item is string then
			lines[len] = ("  "):rep(indent) .. item
		else
			lines[len] = ("  "):rep(indent) .. item[1]
			if not states[item] then
				states[item] = { enabled = false }
			end
			local s <const> = states[item]
			s.line = len
			if s.enabled then
				appendItem(lines, item[2], indent + 1)
			end
		end
	end
	local function renderMenu()
		local lines <const> = {}
		for _, item in ipairs(self.items) do
			appendItem(lines, item, 0)
		end
		d:setLines(lines)
	end

	local function iter(): string
		renderMenu()
		local pressed <const> = waitForKey("<cr>", "<bs>")
		if pressed == "<cr>" then
			local row <const> = d:getCursor()
			for item, state in pairs(states) do
				if state.line == row and item is string then
					d:close()
					return item
				end
			end
			return ""
		elseif pressed == "<bs>" then
			d:close()
			return
		end
	end
	return iter
end

return menu
