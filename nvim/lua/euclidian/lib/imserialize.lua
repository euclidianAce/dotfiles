

local Options = {}



local Writable = {}

local imserialize = {
   Options = Options,
   Writable = Writable,
   string = nil,
   number = nil,
   integer = nil,
   array = nil,
   boolean = nil,
}

local currentOpts = nil
local currentIndent = 0
local currentWriter = nil

local State = {}












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
local function currentState()
   return stateStack[#stateStack]
end

function imserialize.start(target, opts)
   assert(not currentWriter)
   currentWriter = target
   currentIndent = 0
   currentOpts = opts or {}
   pushState()
end

function imserialize.finish()
   assert(currentWriter)
   if type(currentWriter) == "userdata" then
      currentWriter:flush()
   end
   currentWriter = nil
   currentOpts = nil
   stateStack = {}
end

local function rawWrite(str)
   assert(currentWriter)
   if type(currentWriter) == "userdata" then
      currentWriter:write(str)
   else
      table.insert(currentWriter, str)
   end
end

local function write(str)
   assert(currentWriter)
   rawWrite(str)
end

local function flush(s)
   for _, v in ipairs(s.queue) do
      rawWrite(v)
   end
   s.queue = {}
end

local function qWrite(s, str)
   table.insert(s.queue, str)
end

local function qIndent(s)
   if currentOpts.indent then
      table.insert(s.queue, currentOpts.indent:rep(currentIndent))
   end
end

local function indent()
   if currentOpts.indent then
      rawWrite((currentOpts.indent):rep(currentIndent))
   end
end

local function qNewline(s)
   if currentOpts.newlines then
      table.insert(s.queue, "\n")
   end
end

local function newline()
   if currentOpts.newlines then
      rawWrite("\n")
   end
end

local function shouldPrefixWithComma(s)
   return not s.raw and
   s.idx > 0 and
   s.lastEntryKind == "value"
end
local function shouldPostfixWithComma(s)
   return not s.raw and
   s.lastEntryKind == "key"
end

local function value(fn)
   return function(...)
      local s = currentState()
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

imserialize.string = value(function(val)
   write(("%q"):format(val))
end)

imserialize.number = value(function(val, prec)
   prec = prec or 2
   write(("%." .. prec .. "f"):format(val))
end)

imserialize.integer = value(function(val)
   write(("%d"):format(val))
end)

function imserialize.numberOrInteger(val, prec)
   if math.floor(val) == val then
      imserialize.integer(val)
   else
      imserialize.number(val, prec)
   end
end

imserialize.boolean = value(function(val)
   write(val and "true" or "false")
end)

local defaults = {
   number = imserialize.numberOrInteger,
   string = imserialize.string,
   boolean = imserialize.boolean,
}

function imserialize.any(val)
   assert(defaults[type(val)], "Value of type " .. type(val) .. " is not generically serializable")
   defaults[type(val)](val)
end

local function open(str)
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
local function close(s)
   currentIndent = currentIndent - 1
   popState()
   newline()
   indent()
   write(s)
end

imserialize.array = value(function(val)
   write("{ ")

   pushState()
   local s = currentState()
   for _, v in ipairs(val) do
      imserialize.any(v)
      s.idx = s.idx + 1
   end
   popState()

   write(" }")
   s.lastEntryKind = "value"
end)

function imserialize.beginTable()
   open("{")
   currentState().inTable = true
end

function imserialize.endTable()
   assert(currentState().lastEntryKind ~= "key", "Attempt to end a table directly after a key")
   assert(currentState().inTable, "Attempt to end a table when not in a table")
   close("}")
   currentState().lastEntryKind = "value"
end

function imserialize.key(val)
   local s = currentState()
   flush(s)
   local old = s.raw
   if shouldPrefixWithComma(s) then
      write(",")
      newline()
      indent()
   end
   s.raw = true
   if type(val) == "string" then
      if val:match("^[a-zA-Z_][a-zA-Z_0-9]*$") then
         write(val)
      else
         write("[")
         imserialize.string(val)
         write("]")
      end
   elseif type(val) == "number" then
      write("[")
      imserialize.numberOrInteger(val)
      write("]")
   else
      error("Not implemented: key of " .. type(val))
   end

   write(" = ")
   s.lastEntryKind = "key"
   s.raw = old
end

return imserialize