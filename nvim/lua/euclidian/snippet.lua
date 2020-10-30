
local a = vim.api

local function cmdf(fmt, ...)
   a.nvim_command(string.format(fmt, ...))
end

local snippet = {}

local Snippet = {}





local Evaluator = {BufWinInfo = {}, }






















local snippets = {}
local evaluators = {}

local function createEvaluator(kind)

   local origWin = a.nvim_get_current_win()
   local origBuf = a.nvim_get_current_buf()
   local cursorRow = a.nvim_win_get_cursor(origWin)[1]
   local outputBuf = a.nvim_create_buf(false, true)
   local outputWin = a.nvim_open_win(outputBuf, false, {
      relative = "cursor", style = "minimal", anchor = "NW",
      width = 50, height = 5,
      row = -2, col = -4,
   })
   local inputBuf = a.nvim_create_buf(false, true)
   local inputWin = a.nvim_open_win(inputBuf, true, {
      relative = "cursor", style = "minimal", anchor = "NW",
      width = 50, height = 5,
      row = 1, col = -4,
   })




   a.nvim_win_set_option(outputWin, "winhl", "NormalFloat:Special")
   local e = {
      kind = kind,
      cursorRow = cursorRow,
      input = { buf = inputBuf, win = inputWin },
      output = { buf = outputBuf, win = outputWin },
      orig = { buf = origBuf, win = origWin },
   }
   evaluators[origWin] = e
   cmdf([[autocmd TextChanged,TextChangedI <buffer=%d> lua require'euclidian.snippet'.eval(%d)]], e.input.buf, e.orig.win)
   cmdf([[inoremap <silent> <buffer> <CR> <Esc>:lua require'euclidian.snippet'.step(%d)<CR>]], e.orig.win)
   cmdf([[nnoremap <silent> <buffer> <CR> <Esc>:lua require'euclidian.snippet'.step(%d)<CR>]], e.orig.win)
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
         return a.nvim_buf_get_lines(e.input.buf, 0, -1, false)[1]
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


local stub = function() end
local function evaluate(e)
   if e.kind == "start" then
      local name = a.nvim_buf_get_lines(e.input.buf, 0, -1, false)[1]
      if snippets[name] then
         e.kind = "snippet"
         e.snippetStep = 1
         e.snippetInput = {}
         e.snippet = snippets[name]
         a.nvim_buf_set_lines(e.input.buf, 0, -1, false, {})
         a.nvim_buf_set_lines(e.output.buf, 0, -1, false, vim.split(snippets[name].content, "\n"))
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
      local ok, res = pcall(func)
      local data = vim.split(tostring(res or ""), "\n", true)
      a.nvim_buf_set_lines(e.output.buf, 0, -1, false, data)
   end
end

local function putResult(e)
   local result = a.nvim_buf_get_lines(e.output.buf, 0, -1, false)
   delete(e)
   a.nvim_put(result, "l", true, true)
end

local function step(e)
   local content = a.nvim_buf_get_lines(e.input.buf, 0, -1, false)[1]
   if e.kind == "snippet" then
      table.insert(e.snippetInput, content)
      if e.snippetStep == e.snippet.length then
         putResult(e)
         evaluators[e.orig.win] = nil
      end
      a.nvim_buf_set_lines(e.input.buf, 0, -1, false, {})
      updateEvalBuf(e)
      e.snippetStep = e.snippetStep + 1
      cmdf("startinsert")
   elseif e.kind == "lua" then
      putResult(e)
      evaluators[e.orig.win] = nil
   end
end

function snippet.eval(winId)    evaluate(evaluators[winId]) end
function snippet.step(winId)    step(evaluators[winId]) end
function snippet.create(name, content, defaults)
   snippets[name] = {
      content = content,
      defaults = defaults or {},
   }
   snippets[name].length = select(2, content:gsub("%%%d+", "%1"))
end

function snippet.start()
   createEvaluator("start")
end

return snippet