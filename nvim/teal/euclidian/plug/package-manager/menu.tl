
local dialog <const> = require("euclidian.lib.dialog")
local z <const> = require("euclidian.lib.async.zig")

-- TODO: find a way to make this generic over the function return so
--       run can return the result of the function with the correct type
local record Accordion
	type Item = {string, {Item} | function(): any...}
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
		expanded_prefix = "- ",
		unexpanded_prefix = "+ ",
	}, { __index = Accordion })
end

local menu <const> = {
	Accordion = Accordion,
	new = new,
}

local function waitForKey(d: dialog.Dialog, ...: string): string
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

local ns <const> = vim.api.nvim_create_namespace("euclidian.plug.package-manager.menu")

function Accordion:run(opts: dialog.Dialog.Opts): any...
	local d <const> = dialog.new(opts)

	local record State
		enabled: boolean
		line: integer
	end
	local states <const>: {Accordion.Item:State} = {}
	local lines: {string}
	local function appendItem(item: Accordion.Item, indent: integer)
		local len <const> = #lines + 1
		local second <const> = item[2]
		if not states[item] then
			states[item] = { enabled = false }
		end
		local s <const> = states[item]
		s.line = len
		local prefix: string = ""
		if second is function(): any... then
			prefix = self.item_prefix
		elseif second then
			prefix = s.enabled
				and self.expanded_prefix
				or self.unexpanded_prefix
		end
		lines[len] = ("  "):rep(indent)
			.. prefix
			.. item[1]
		if second is {Accordion.Item} and s.enabled then
			for _, child in ipairs(second) do
				appendItem(child, indent + 1)
			end
		end
	end
	local function renderMenu()
		lines = {}
		for _, item in ipairs(self.items) do
			appendItem(item, 0)
		end
		d:setLines(lines)
	end

	local buf <const> = d:buf()
	local win <const> = d:win()
	local winid <const> = win.id
	win:setOption("winhl", win:getOption("winhl") as string)
	win:setOption("cursorline", true)
	buf:clearNamespace(ns, 0, -1)
	vim.api.nvim_set_decoration_provider(ns, {
		on_win = function(_: any, w: integer): boolean
			if winid ~= w then
				return false
			end
			return true
		end,
		on_line = function(_: any, _win: integer, bufnr: integer, row: integer): boolean
			if bufnr ~= buf.id then
				return false
			end
			local line <const> = lines[row+1]
			local leadingws <const> = #line:match("^(%s*)")
			buf:setExtmark(ns, row, leadingws, {
				ephemeral = true,
				end_line = row,
				end_col = #line,
				hl_group = line:match("^%s*%*") and "Type"
					or line:match("^%s*[+-]") and "Special"
					or "Normal",
			})

			return true
		end,
	})

	while true do
		renderMenu()
		local pressed <const> = waitForKey(d, "<cr>", "<tab>", "<bs>")
		if pressed == "<cr>" or pressed == "<tab>" then
			local row <const> = d:getCursor()
			for item, state in pairs(states) do
				local second <const> = item[2]
				if state.line == row then
					if second is function(): any... and pressed == "<cr>" then
						d:close()
						return second()
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
