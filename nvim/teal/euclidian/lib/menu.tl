local dialog <const> = require("euclidian.lib.dialog")
local input <const> = require("euclidian.lib.input")
local nvim <const> = require("euclidian.lib.nvim")
-- local z <const> = require("euclidian.lib.azync")
local ns <const> = nvim.api.createNamespace("euclidian.lib.menu")

-- TODO: find a way to make this generic over the function return so
--       run can return the result of the function with the correct type
local record Accordion
	type Item = string | {string, {Item} | function(): any...}
	items: {Item}
	item_prefix: string
	unexpanded_prefix: string
	expanded_prefix: string

	record Options
		persist: boolean -- don't close dialog after selecting an item
	end
	redraw: function()

	metamethod __call: function(Accordion, dialog.Dialog, Options): any...
end

local record Modifiable
	record Item
		name: string
		value: string
		validator: function(string): boolean, string
	end

	items: {Item}

	metamethod __call: function(Modifiable, dialog.Dialog): any...
end

local record Checklist
	type Item = {string, boolean} | string
	items: {Item}
	checked_prefix: string
	unchecked_prefix: string

	metamethod __call: function(Checklist, dialog.Dialog): {string}
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

local checklistMt <const>: metatable<Checklist> = { __index = Checklist }

function new.checklist(items: {Checklist.Item}): Checklist
	return setmetatable({
		items = items,
		checked_prefix = "[*] ",
		unchecked_prefix = "[ ] ",
	} as Checklist, checklistMt)
end

local menu <const> = {
	Accordion = Accordion,
	Modifiable = Modifiable,
	Checklist = Checklist,
	new = new,
}

function accordionMt.__call(self: Accordion, d: dialog.Dialog, opts: Accordion.Options): any...
	opts = opts or {}

	local buf <const> = d:ensureBuf()
	local win <const> = d:ensureWin()

	local record State
		enabled: boolean
		line: integer
	end
	local states: {Accordion.Item:State} = {}
	local lines: {string} = {}
	local function renderMenu()
		local extmarks <const>: {any} = {}

		local function appendItem(item: Accordion.Item, indent: integer)
			local len <const> = #lines + 1
			if item is string then
				lines[len] = ("  "):rep(indent) .. item
			else
				local second <const> = item[2]
				if not states[item] then
					states[item] = { enabled = false }
				end
				local s <const> = states[item]
				s.line = len
				local prefix = ""
				local hl = "Normal"
				if second is function(): any... then
					prefix = self.item_prefix
					hl = "Type"
				elseif second then
					prefix = s.enabled
						and self.expanded_prefix
						or self.unexpanded_prefix
					hl = "Special"
				end
				lines[len] = ("  "):rep(indent) .. prefix .. item[1]
				table.insert(
					extmarks,
					{ len - 1, indent * 2, {
						end_row = len - 1,
						end_col = #lines[len],
						hl_group = hl,
					} }
				)
				if second is {Accordion.Item} and s.enabled then
					for _, child in ipairs(second) do
						appendItem(child, indent + 1)
					end
				end
			end
		end

		buf:clearNamespace(ns, 0, -1)
		lines = {}
		for _, state in pairs(states) do
			state.line = -1
		end
		for _, item in ipairs(self.items) do
			appendItem(item, 0)
		end
		d:setLines(lines)
		vim.schedule(function()
			for _, mark in ipairs(extmarks as {{integer, integer, {string:any}}}) do
				buf:setExtmark(ns, mark[1], mark[2], mark[3])
			end
		end)
	end

	self.redraw = renderMenu

	win:setOption("winhl", win:getOption("winhl") as string)
	win:setOption("cursorline", true)

	repeat
		renderMenu()
		local pressed <const> = input.waitForKey(d:buf(), "n", "<cr>", "<tab>", "<bs>", "<2-LeftMouse>")

		if pressed == "<cr>" or pressed == "<tab>" or pressed == "<2-LeftMouse>" then
			local row <const> = d:getCursor()
			for item, state in pairs(states) do
				if not item is string then
					local second <const> = item[2]
					if state.line == row then
						if second is function(): any... and (pressed == "<cr>" or pressed == "<2-LeftMouse>") then
							if opts.persist then
								second()
							else
								d:close()
								self.redraw = nil
								return second()
							end
						else
							state.enabled = not state.enabled
						end
					end
				end
			end
		end
	until pressed == "<bs>"
	d:close()
	self.redraw = nil
end

function modifiableMt.__call(self: Modifiable, d: dialog.Dialog)
	local function render()
		local lines <const> = {}
		for i, item in ipairs(self.items) do
			lines[i] = item.name .. ": " .. tostring(item.value)
		end
		d:setLines(lines)
	end

	repeat
		render()
		local pressed <const> = input.waitForKey(d:buf(), "n", "<cr>", "<bs>")
		if pressed == "<cr>" then
			d:focus()
			local row <const> = d:getCursor()
			local item <const> = self.items[row]
			local val: string
			repeat
				val = input.input{ prompt = "New Value for " .. item.name .. ": " }
				local ok = true
				if not rawequal(val, nil) then
					local err: string
					ok, err = item.validator(val)
					if ok then
						item.value = val
					else
						nvim.api.errWriteln(
							("Invalid input for item %q: %s"):format(
								item.name,
								assert(err, "no error message was returned from the validator")
							)
						)
					end
				end
			until ok
		elseif pressed == "<bs>" then
			break
		end
	until pressed == "<bs>"

	d:close()
end

function checklistMt.__call(self: Checklist, d: dialog.Dialog): {string}
	local function render()
		local lines <const> = {}
		for i, item in ipairs(self.items) do
			if item is string then
				lines[i] = self.unchecked_prefix .. item
			else
				lines[i] = (item[2] and self.checked_prefix or self.unchecked_prefix) .. item[1]
			end
		end
		d:setLines(lines)
	end

	local function toggleItem(i: integer)
		if type(self.items[i]) == "string" then
			self.items[i] = {self.items[i] as string, true}
		else
			(self.items[i] as {string, boolean})[2] = not (self.items[i] as {string, boolean})[2]
		end
	end

	repeat
		render()
		local pressed <const> = input.waitForKey(d:buf(), "n", "<cr>", "<tab>", "<bs>", "<c-y>")
		if pressed == "<cr>" or pressed == "<tab>" then
			toggleItem((d:getCursor()))
		elseif pressed == "<c-y>" then
			local ret <const>: {string} = {}
			for _, v in ipairs(self.items) do
				if v is {string, boolean} and v[2] then
					table.insert(ret, v[1])
				end
			end
			return ret
		end
	until pressed == "<bs>"
end

return menu
