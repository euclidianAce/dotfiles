-- immediate mode serialization

local record Options
	newlines: boolean
	indent: string
end
local type Writable = FILE | {string}

local imserialize <const> = {
	Options = Options,
	Writable = Writable,
	string: function(string) = nil,
	number: function(number, integer) = nil,
	integer: function(integer) = nil,
	array: function({any}) = nil,
	boolean: function(boolean) = nil,
}

local currentOpts: Options = nil
local currentIndent: integer = 0
local currentWriter: Writable = nil

local record State
	idx: integer
	raw: boolean
	enum Entry
		"key"
		"value"
		"comma"
	end
	lastEntryKind: Entry
	queue: {string}
	inTable: boolean
end

local stateStack = {}
local function pushState()
	table.insert(stateStack, {
		idx = 0,
		queue = {},
	})
end
local function popState()
	table.remove(stateStack)
end
local function currentState(): State
	return stateStack[#stateStack]
end

function imserialize.start(target: Writable, opts: Options)
	assert(not currentWriter)
	currentWriter = target
	currentIndent = 0
	currentOpts = opts or {}
	pushState()
end

function imserialize.finish()
	assert(currentWriter)
	if currentWriter is FILE then
		currentWriter:flush()
	end
	currentWriter = nil
	currentOpts = nil
	stateStack = {}
end

local function rawWrite(str: string)
	assert(currentWriter)
	if currentWriter is FILE then
		currentWriter:write(str)
	else
		table.insert(currentWriter, str)
	end
end

local function write(str: string)
	assert(currentWriter)
	rawWrite(str)
end

local function flush(s: State)
	for _, v in ipairs(s.queue) do
		rawWrite(v)
	end
	s.queue = {}
end

local function qWrite(s: State, str: string)
	table.insert(s.queue, str)
end

local function qIndent(s: State)
	if currentOpts.indent then
		table.insert(s.queue, currentOpts.indent:rep(currentIndent))
	end
end

local function indent()
	if currentOpts.indent then
		rawWrite((currentOpts.indent):rep(currentIndent))
	end
end

local function qNewline(s: State)
	if currentOpts.newlines then
		table.insert(s.queue, "\n")
	end
end

local function newline()
	if currentOpts.newlines then
		rawWrite("\n")
	end
end

local function shouldPrefixWithComma(s: State): boolean
	return not s.raw
		and s.idx > 0
		and s.lastEntryKind == "value"
end
local function shouldPostfixWithComma(s: State): boolean
	return not s.raw
		and s.lastEntryKind == "key"
end

local function value<Args...>(fn: function(Args)): function(Args)
	return function(...: Args)
		local s <const> = currentState()
		flush(s)

		if s.raw then
			fn(...)
			return
		end

		if shouldPrefixWithComma(s) then
			write(", ")
		end

		fn(...)

		s.idx = s.idx + 1
		if shouldPostfixWithComma(s) then
			qWrite(s, ",")
			qNewline(s)
			qIndent(s)
			s.lastEntryKind = "comma"
		else
			s.lastEntryKind = "value"
		end
	end
end

imserialize.string = value(function(val: string)
	write(("%q"):format(val))
end)

imserialize.number = value(function(val: number, prec: integer)
	prec = prec or 2
	write(("%." .. prec .. "f"):format(val))
end)

imserialize.integer = value(function(val: integer)
	write(("%d"):format(val))
end)

function imserialize.numberOrInteger(val: number, prec: integer)
	if math.floor(val) == val then
		imserialize.integer(val as integer)
	else
		imserialize.number(val, prec)
	end
end

imserialize.boolean = value(function(val: boolean)
	write(val and "true" or "false")
end)

local defaults <const>: {string : function(any)} = {
	number = imserialize.numberOrInteger,
	string = imserialize.string,
	boolean = imserialize.boolean,
}

function imserialize.any(val: any)
	assert(defaults[type(val)], "Value of type " .. type(val) .. " is not generically serializable")
	defaults[type(val)](val)
end

local function open(str: string)
	local s = currentState()
	flush(s)
	if shouldPrefixWithComma(s) then
		write(", ")
	end
	write(str)
	currentIndent = currentIndent + 1
	pushState()
	s = currentState()
	qNewline(s)
	qIndent(s)
end
local function close(s: string)
	currentIndent = currentIndent - 1
	popState()
	newline()
	indent()
	write(s)
end

imserialize.array = value(function(val: {any})
	write("{ ")

	pushState()
	local s <const> = currentState()
	for _, v in ipairs(val) do
		imserialize.any(v)
		s.idx = s.idx + 1
	end
	popState()

	write(" }")
	s.lastEntryKind = "value"
end)

function imserialize.beginTable()
	flush(currentState())
	open("{")
	currentState().inTable = true
end

function imserialize.endTable()
	assert(currentState().lastEntryKind ~= "key", "Attempt to end a table directly after a key")
	assert(currentState().inTable, "Attempt to end a table when not in a table")
	close("}")
	local s <const> = currentState()
	s.idx = s.idx + 1
	s.lastEntryKind = "value"
end

function imserialize.key(val: any)
	local s <const> = currentState()
	flush(s)
	local old <const> = s.raw
	if shouldPrefixWithComma(s) then
		write(",")
		newline()
		indent()
	end
	s.raw = true
	if val is string then
		if val:match("^[a-zA-Z_][a-zA-Z_0-9]*$") then
			write(val)
		else
			write("[")
			imserialize.string(val)
			write("]")
		end
	elseif val is number then
		write("[")
		imserialize.numberOrInteger(val as number)
		write("]")
	else
		error("Not implemented: key of " .. type(val))
	end

	write(" = ")
	s.lastEntryKind = "key"
	s.raw = old
end

return imserialize
