
local dialog <const> = require("euclidian.lib.dialog")
-- local nvim <const> = require("euclidian.lib.nvim")
local z <const> = require("euclidian.lib.async.zig")

-- local type NilFrame = z.Frame<nil>

local record Accordion
	type Item = {string, function | {Item}}
	items: {Item}
	item_prefix: string
	unexpanded_prefix: string
	expanded_prefix: string
end

local new <const> = {}

function new.accordion(items: {Accordion.Item}): Accordion
	return setmetatable({
		items = items,
		item_prefix = "* ",
		expanded_prefix = "v ",
		unexpanded_prefix = "> ",
	}, { __index = Accordion })
end

local menu <const> = {
	Accordion = Accordion,
	new = new,
}

-- TODO: use decorations to highlight branches/leaves differently
function Accordion:run(opts: dialog.Dialog.Opts)
	local d <const> = dialog.new(opts)
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

	local record State
		enabled: boolean
		line: integer
	end
	local states <const>: {Accordion.Item:State} = {}
	local function appendItem(lines: {string}, item: Accordion.Item, indent: integer)
		local len <const> = #lines + 1
		local second <const> = item[2]
		if not states[item] then
			states[item] = { enabled = false }
		end
		local s <const> = states[item]
		s.line = len
		lines[len] = ("  "):rep(indent)
			.. (second is function and self.item_prefix
					or s.enabled and self.expanded_prefix
					or self.unexpanded_prefix)
			.. item[1]
		if second is {Accordion.Item} and s.enabled then
			for _, child in ipairs(second) do
				appendItem(lines, child, indent + 1)
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

	while true do
		renderMenu()
		local pressed <const> = waitForKey("<cr>", "<tab>", "<bs>")
		if pressed == "<cr>" or pressed == "<tab>" then
			local row <const> = d:getCursor()
			for item, state in pairs(states) do
				local second <const> = item[2]
				if state.line == row then
					if second is function and pressed == "<cr>" then
						d:close()
						second()
						return
					else
						state.enabled = not state.enabled
					end
				end
			end
		elseif pressed == "<bs>" then
			d:close()
			return
		end
	end
end

return menu
