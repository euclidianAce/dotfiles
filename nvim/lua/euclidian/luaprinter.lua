


local a = vim.api
local M = {}

local LuaBuffer = {}






local cache = setmetatable({}, { __mode = "v" })

local function getLuaBuf(buf)
   buf = buf or a.nvim_get_current_buf()
   if cache[buf] then
      return cache[buf], true
   end
   local ft = a.nvim_buf_get_option(buf, "filetype")
   local ns = a.nvim_create_namespace("luaprinter")
   local lbuf = {
      buf = buf,
      ns = ns,
      printed = {},
      isTeal = ft == "teal",
   }
   cache[buf] = lbuf
   return lbuf, false
end

local newPrint = ([[
stdout_write = io.write
print = function(...)
	local inspect_opts = {newline = " ", tab = ""}
	local ok, inspect = pcall(require, "inspect")
	if not ok then inspect = tostring end
	stdout_write(string.char(1), debug.getinfo(2, "l").currentline, string.char(1))
	for i = 1, select("#", ...) do
		stdout_write(inspect((select(i, ...)), inspect_opts))
		if i < select("#", ...) then
			stdout_write(", ")
		end
	end
	stdout_write(string.char(1))
end
io.write = print
]]):gsub("\n", ";")


local function compileTealBuf(buf)
   local lines = a.nvim_buf_get_lines(buf, 0, -1, false)
   local code = table.concat(lines, "\n")
   local tl = require("tl")

   local luaCode = tl.gen(code) or ""
   return newPrint .. luaCode
end

local loop = vim.loop
local function runBuffer(b, timeout, cb)
   timeout = timeout or 10000
   b.printed = {}
   local function onread(err, data)
      if err then          error(err) end
      if data then
         for lnum, str in data:gmatch(string.char(1) .. "(%d+)" .. string.char(1) .. "(.-)" .. string.char(1)) do
            local lineNum = tonumber(lnum)
            if not b.printed[lineNum] then
               b.printed[lineNum] = {}
            end
            table.insert(b.printed[lineNum], str)
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
         for linenum, data in pairs(b.printed) do
            a.nvim_buf_set_virtual_text(b.buf, b.ns, linenum - 1, { { table.concat(data, "  "):gsub("\n", " "), "Comment" } }, {})
         end
         if cb then             cb() end
      end
   end)
   local name = a.nvim_buf_get_name(b.buf)
   local args = {}

   table.insert(args, "-e")
   if b.isTeal then
      table.insert(args, compileTealBuf(b.buf))
   else
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

local cmd = a.nvim_command
function M.attach(buf)
   buf = buf or a.nvim_get_current_buf()
   cmd("augroup luaprinter")
   cmd("autocmd BufWritePost <buffer=" .. buf .. "> lua require('euclidian.luaprinter').runBuffer(" .. buf .. ", 10000)")

   cmd("augroup END")
   local fname = a.nvim_buf_get_name(buf)
   print("[euclidian.luaprinter] Attached lua printer to buffer", buf, "(", fname, ")")
end

function M.getLine(lineNum, bufNum)
   local b, wasCached = getLuaBuf(bufNum)
   local function createWin()
      local buf = a.nvim_create_buf(false, true)
      local win = a.nvim_open_win(buf, true, {
         relative = "cursor", style = "minimal", anchor = "NW",
         width = 65, height = 15,
         row = 1, col = 0,
      })
      a.nvim_buf_set_lines(buf, 0, -1, false, b.printed[lineNum] or { "[euclidian.luaprinter] Nothing was printed on this line :D" })
   end
   if not wasCached then
      M.attach(bufNum or a.nvim_get_current_buf())
      runBuffer(b, 1000, createWin)
   else
      createWin()
   end
end

return M
