local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")
local z <const> = require("euclidian.lib.azync")
local ns <const> = vim.api.nvim_create_namespace("euclidian.plug.package-manager.menu")

-- TODO: find a way to make this generic over the function return so
--       run can return the result of the function with the correct type
local record Accordion
	-- TODO: allow an item to be just a string
	type Item = {string, {Item} | function(): any...}
	items: {Item}
	item_prefix: string
	unexpanded_prefix: string
	expanded_prefix: string

	metamethod __call: function(Accordion, dialog.Dialog.Opts): any...
end

local record Modifiable
	record Item
		name: string
		value: string
		validator: function(string): boolean, string
	end

	items: {Item}

	metamethod __call: function(Modifiable, dialog.Dialog.Opts)
end

local new <const> = {}
local accordionMt <const>: metatable<Accordion> = { __index = Accordion }

function new.accordion(items: {Accordion.Item}): Accordion
	return setmetatable({
		items = items,
		item_prefix = "* ",
		expanded_prefix = "- ",
		unexpanded_prefix = "+ ",
	} as Accordion, accordionMt)
end

local modifiableMt <const>: metatable<Modifiable> = { __index = Modifiable }

function new.modifiable(items: {Modifiable.Item}): Modifiable
	return setmetatable({
		items = items,
	} as Modifiable, modifiableMt)
end

local menu <const> = {
	Accordion = Accordion,
	Modifiable = Modifiable,
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
	end) as function(): nil)
	return pressed
end

function accordionMt.__call(self: Accordion, opts: dialog.Dialog.Opts, onOpen: function(dialog.Dialog)): any...
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

	if onOpen then onOpen(d) end

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

local function longestLength<T>(arr: {T}): integer
	local longest = 0
	for _, v in ipairs(arr) do
		local len <const> = #(v as table)
		if len > longest then
			longest = len
		end
	end
	return longest
end

function modifiableMt.__call(self: Modifiable, opts: dialog.Dialog.Opts)
	local d <const> = dialog.new(opts)

	local function render()
		local lines <const> = {}
		for i, item in ipairs(self.items) do
			lines[i] = item.name .. ": " .. tostring(item.value)
		end
		d:setLines(lines)
	end

	local function editDialog(item: Modifiable.Item, resume: z.Frame<nil>)
		local editor <const> = dialog.new{
			wid = 1,
			hei = 1,
			centered = true,
			interactive = true,
			ephemeral = true,
		}
		local lines = {
			"(Name): " .. item.name,
			"(Old Value): " .. tostring(item.value),
		}
		local width <const> = longestLength(lines) + 10
		editor:setLines(lines)
		editor:buf():attach(false, {
			on_lines = function()
				editor:fitTextPadded(1, 0, width, 3, nil, nil):centerHorizontal()
			end,
		})
		editor:fitText(width, 2):centerHorizontal()
		local close <const> = vim.schedule_wrap(function()
			nvim.command("stopinsert")
			editor:close()
			z.resume(resume)
		end)
		local function accept(input: string)
			item.value = input
			close()
		end
		editor:setPrompt(
			"(New Value): ",
			function(input: string)
				if item.validator then
					local ok <const>, err <const> = item.validator(input)
					if ok then
						accept(input)
					else
						vim.api.nvim_err_writeln(
							("Invalid input for item %q: %s"):format(item.name, tostring(err))
						)
						vim.schedule(function()
							editor:setLines(lines)
						end)
					end
				else
					accept(input)
				end
			end,
			close
		)
	end

	while true do
		render()
		local pressed <const> = waitForKey(d, "<cr>", "<bs>")
		if pressed == "<cr>" then
			local row <const> = d:getCursor()
			z.suspend(function(me: z.Frame<nil>)
				editDialog(self.items[row], me)
			end)
		elseif pressed == "<bs>" then
			break
		end
	end

	d:close()
end

return menu
