
local a = vim.api
local cmdf = require("euclidian.lib.util").nvim.cmdf

local snippet = {}

local Snippet = {}



local ResolvedSnippet = {}





local Evaluator = {BufWinInfo = {}, }






















local snippets = {}
local ftSnippets = setmetatable({}, {
   __index = function(self, key)
      local t = {}
      rawset(self, key, t)
      return t
   end,
})
local evaluators = {}

local function createEvaluator(kind)

   local origWin = a.nvim_get_current_win()
   local origBuf = a.nvim_get_current_buf()
   local cursorRow = a.nvim_win_get_cursor(origWin)[1]
   local outputBuf = a.nvim_create_buf(false, true)
   local outputWin = a.nvim_open_win(outputBuf, false, {
      relative = "cursor", style = "minimal", anchor = "NW",
      width = 50, height = 5,
      row = -7, col = -4,
   })
   local inputBuf = a.nvim_create_buf(false, true)
   local inputWin = a.nvim_open_win(inputBuf, true, {
      relative = "cursor", style = "minimal", anchor = "NW",
      width = 50, height = 5,
      row = 3, col = -4,
   })

   local ft = a.nvim_buf_get_option(origBuf, "filetype")
   a.nvim_buf_set_option(outputBuf, "filetype", ft)

   a.nvim_win_set_option(outputWin, "winblend", 15)
   a.nvim_win_set_option(inputWin, "winblend", 15)

   local e = {
      kind = kind,
      cursorRow = cursorRow,
      input = { buf = inputBuf, win = inputWin },
      output = { buf = outputBuf, win = outputWin },
      orig = { buf = origBuf, win = origWin },
   }
   evaluators[origWin] = e
   cmdf([[autocmd TextChanged,TextChangedI <buffer=%d> lua require'euclidian.lib.snippet'.eval(%d)]], e.input.buf, e.orig.win)
   cmdf([[inoremap <silent> <buffer> <CR> <cmd>lua require'euclidian.lib.snippet'.step(%d)<CR>]], e.orig.win)
   cmdf([[nnoremap <silent> <buffer> <CR> <cmd>lua require'euclidian..lib.snippet'.step(%d)<CR>]], e.orig.win)
   cmdf("startinsert")

   return e
end

local function updateEvalBuf(e)
   a.nvim_buf_set_lines(
   e.output.buf,
   0, -1, false,
   vim.split(
   (e.snippet.content:gsub("%%(%d+)", function(m)
      local n = tonumber(m)
      if not n then
         return m
      elseif n - 1 == #e.snippetInput then
         local res = a.nvim_buf_get_lines(e.input.buf, 0, -1, false)[1]
         return res ~= "" and
         res or
         e.snippet.defaults[n] or
         ""
      else
         return e.snippetInput[n]
      end
   end)),
   "\n"))


end

local function delete(e)
   a.nvim_win_close(e.input.win, true)
   a.nvim_win_close(e.output.win, true)
   evaluators[e.orig.win] = nil
end

local function putResult(e)
   local result = a.nvim_buf_get_lines(e.output.buf, 0, -1, false)
   local currentLineContent = a.nvim_buf_get_lines(e.orig.buf, e.cursorRow - 1, e.cursorRow, false)[1]
   local offset = 1
   if vim.trim(currentLineContent) == "" then
      offset = 0
   end
   a.nvim_buf_set_lines(e.orig.buf, e.cursorRow - 1, e.cursorRow - offset, false, result)
   a.nvim_win_set_cursor(e.orig.win, { e.cursorRow, 0 })
   delete(e)
   a.nvim_input(string.format("<Esc>%d==", #result))
end

local function getSnippetLength(txt)
   local len = 0
   for d in txt:gmatch("%%(%d+)") do
      if tonumber(d) > len then
         len = tonumber(d)
      end
   end
   return len
end
local function resolveSnippet(snip, buf)
   if not snip then return end
   local content = snip.content
   if type(content) == "function" then
      local newContent = content(buf) or ""
      return {
         length = getSnippetLength(newContent),
         content = newContent,
         defaults = snip.defaults,
      }
   else
      return {
         length = getSnippetLength(content),
         content = content,
         defaults = snip.defaults,
      }
   end
end

local stub = function() end
local function evaluate(e)
   if e.kind == "start" then
      local current_ft = a.nvim_buf_get_option(e.orig.buf, "ft")
      local name = a.nvim_buf_get_lines(e.input.buf, 0, -1, false)[1]

      local snip = resolveSnippet(ftSnippets[current_ft][name] or snippets[name], e.orig.buf)

      if snip then
         a.nvim_buf_set_lines(e.output.buf, 0, -1, false, vim.split(snip.content, "\n"))
         if snip.length == 0 then
            putResult(e)
         else
            e.kind = "snippet"
            e.snippetStep = 1
            e.snippetInput = {}
            e.snippet = snip
            a.nvim_buf_set_lines(e.input.buf, 0, -1, false, {})
         end
      elseif name == "lua" then
         e.kind = "lua"
         a.nvim_buf_set_lines(e.input.buf, 0, -1, false, {})
         a.nvim_buf_set_option(e.input.buf, "ft", "lua")
      end
   elseif e.kind == "snippet" then
      updateEvalBuf(e)
   elseif e.kind == "lua" then
      local code = "return (" .. table.concat(a.nvim_buf_get_lines(e.input.buf, 0, -1, false), " ") .. ")"
      local func = loadstring(code) or stub
      local _, res = pcall(func)
      local data = vim.split(tostring(res or ""), "\n", true)
      a.nvim_buf_set_lines(e.output.buf, 0, -1, false, data)
   end
end

local function step(e)
   local content = a.nvim_buf_get_lines(e.input.buf, 0, -1, false)[1]
   if e.kind == "snippet" then
      if content == "" then
         content = e.snippet.defaults[#e.snippetInput + 1] or content
      end
      table.insert(e.snippetInput, content)
      if e.snippetStep >= e.snippet.length then
         updateEvalBuf(e)
         putResult(e)
      else
         a.nvim_buf_set_lines(e.input.buf, 0, -1, false, {})
         updateEvalBuf(e)
         e.snippetStep = e.snippetStep + 1
         cmdf("startinsert")
      end
   elseif e.kind == "lua" then
      putResult(e)
   else
      delete(e)
   end
end

function snippet.eval(winId) evaluate(evaluators[winId]) end
function snippet.step(winId) step(evaluators[winId]) end

function snippet.create(name, content, defaults)
   snippets[name] = {
      content = content,
      defaults = defaults or {},
   }
end

function snippet.ftCreate(ft, name, content, defaults)
   local snip = {
      content = content,
      defaults = defaults or {},
   }
   if type(ft) == "string" then
      ftSnippets[ft][name] = snip
   else
      for _, v in ipairs(ft) do
         ftSnippets[v][name] = snip
      end
   end
end

function snippet.start()
   createEvaluator("start")
end

return snippet