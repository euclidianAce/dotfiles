local a = vim.api
local M = {}

local LuaBuffer = {}





local cache = setmetatable({}, { __mode = "v" })

local function getLuaBuf(buf)
   buf = buf or (vim.fn.bufnr())
   if cache[buf] then
      return cache[buf]
   end
   local ft = a.nvim_buf_get_option(buf, "filetype")
   local ns = a.nvim_create_namespace("luaprinter")
   return {
      buf = buf,
      ns = ns,
      isTeal = ft == "teal",
   }
end

local function getLeadingNewlines(text)
   return text:match("^\n*") or ""
end
local newPrint = ([[print = function(...)
io.stdout:write(string.char(1), debug.getinfo(2, "l").currentline, string.char(1))
for i = 1, select("#", ...) do
io.stdout:write(inspect((select(i, ...))))
if i < select("#", ...) then
io.stdout:write(", ")
end
end
io.stdout:write(string.char(1))
end;]]):gsub("\n", ";")


local function compileTealBuf(buf)
   local lines = a.nvim_buf_get_lines(buf, 0, -1, false)
   local code = table.concat(lines, "\n")
   local leadingNewlines = getLeadingNewlines(code)
   local tl = require("tl")

   local luaCode = tl.gen(code)
   return newPrint .. leadingNewlines .. luaCode
end

local loop = vim.loop
local function runBuffer(b, timeout)
   timeout = timeout or 10000
   local info = {}
   local function onread(err, data)
      if err then
         error(err)
      end
      if data then
         for lnum, str in data:gmatch(string.char(1) .. "(%d+)" .. string.char(1) .. "(.-)" .. string.char(1)) do
            local lineNum = tonumber(lnum)
            if not info[lineNum] then
               info[lineNum] = {}
            end
            table.insert(info[lineNum], str)
         end
      end
   end

   local stdout = loop.new_pipe(false)
   local stderr = loop.new_pipe(false)
   local handle

   local closed = false
   local close = vim.schedule_wrap(function()
      if not closed then
         closed = true
         stdout:read_stop()
         stderr:read_stop()
         stdout:close()
         stderr:close()
         handle:close()
         a.nvim_buf_clear_namespace(b.buf, b.ns, 0, -1)
         for linenum, data in pairs(info) do
            a.nvim_buf_set_virtual_text(b.buf, b.ns, linenum - 1, { { table.concat(data, "  "), "Comment" } }, {})
         end
      end
   end)
   local name = a.nvim_buf_get_name(b.buf)
   local args = {
      '-l', 'inspect',
   }

   table.insert(args, "-e")
   if b.isTeal then
      table.insert(args, compileTealBuf(b.buf))
   else
      table.insert(args, "-e")
      table.insert(args, newPrint)
      table.insert(args, name)
   end

   handle = loop.spawn("lua", {
      args = args,
      stdio = { stdout, stderr },
   }, close)
   loop.read_start(stdout, onread)
   loop.read_start(stderr, onread)

   vim.defer_fn(close, timeout)
end

function M.runBuffer(buf, timeout)
   runBuffer(getLuaBuf(buf), timeout)
end

return M