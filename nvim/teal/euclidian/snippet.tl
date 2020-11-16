
local a = vim.api

local function cmdf(fmt: string, ...: any)
	a.nvim_command(string.format(fmt, ...))
end

local snippet = {}

local record Snippet
	content: string
	defaults: {string}
	length: number
end

local record Evaluator
	record BufWinInfo
		buf: number
		win: number
	end

	input: BufWinInfo
	output: BufWinInfo
	orig: BufWinInfo
	cursorRow: number

	enum Kind
		"start"
		"snippet"
		"lua"
	end

	snippetStep: number
	snippetInput: {string}
	snippet: Snippet
	kind: Kind
end

local snippets: {string:Snippet} = {}
local ftSnippets: {string:{string:Snippet}} = setmetatable({}, {
	__index = function(self: {string:{string:Snippet}}, key: string): {string:Snippet}
		local t: {string:Snippet} = {}
		rawset(self, key, t)
		return t
	end
})
local evaluators: {number:Evaluator} = {}

local function createEvaluator(kind: Evaluator.Kind): Evaluator
	-- TODO: fiddle with window positions when the cursor is near screen edges
	local origWin <const> = a.nvim_get_current_win()
	local origBuf <const> = a.nvim_get_current_buf()
	local cursorRow <const> = a.nvim_win_get_cursor(origWin)[1]
	local outputBuf <const> = a.nvim_create_buf(false, true)
	local outputWin <const> = a.nvim_open_win(outputBuf, false, {
		relative = "cursor", style = "minimal", anchor = "NW",
		   width = 50,      height = 5,
		     row = -7,         col = -4,
	})
	local inputBuf <const> = a.nvim_create_buf(false, true)
	local inputWin <const> = a.nvim_open_win(inputBuf, true, {
		relative = "cursor", style = "minimal", anchor = "NW",
		   width = 50,      height = 5,
		     row = 3,          col = -4,
	})

	a.nvim_win_set_option(outputWin, "winhl", "NormalFloat:Special")
	local e <const> = {
		kind = kind,
		cursorRow = cursorRow,
		input  = { buf = inputBuf,  win = inputWin  },
		output = { buf = outputBuf, win = outputWin },
		orig   = { buf = origBuf,   win = origWin   },
	}
	evaluators[origWin] = e
	cmdf([[autocmd TextChanged,TextChangedI <buffer=%d> lua require'euclidian.snippet'.eval(%d)]], e.input.buf, e.orig.win)
	cmdf([[inoremap <silent> <buffer> <CR> <cmd>lua require'euclidian.snippet'.step(%d)<CR>]], e.orig.win)
	cmdf([[nnoremap <silent> <buffer> <CR> <cmd>lua require'euclidian.snippet'.step(%d)<CR>]], e.orig.win)
	cmdf("startinsert")
	return e
end

local function updateEvalBuf(e: Evaluator)
	a.nvim_buf_set_lines(
		e.output.buf,
		0, -1, false,
		vim.split(
			(e.snippet.content:gsub("%%(%d+)", function(m: string): string
				local n <const> = tonumber(m)
				if not n then
					return m
				elseif n-1 == #e.snippetInput then
					local res <const> = a.nvim_buf_get_lines(e.input.buf, 0, -1, false)[1]
					return res ~= ""
						and res
						or e.snippet.defaults[n]
						or ""
				else
					return e.snippetInput[n]
				end
			end)),
			"\n"
		)
	)
end

local function delete(e: Evaluator)
	a.nvim_win_close(e.input.win, true)
	a.nvim_win_close(e.output.win, true)
	evaluators[e.orig.win] = nil
end

local function putResult(e: Evaluator)
	local result <const> = a.nvim_buf_get_lines(e.output.buf, 0, -1, false)
	a.nvim_buf_set_lines(e.orig.buf, e.cursorRow-1, e.cursorRow-1, false, result)
	a.nvim_win_set_cursor(e.orig.win, {e.cursorRow, 0})
	delete(e)
	a.nvim_input(string.format("<Esc>%d==", #result))
end

global loadstring: function(string, string): function(...: any): any...
local stub <const> = function() end
local function evaluate(e: Evaluator)
	if e.kind == "start" then
		local current_ft = a.nvim_buf_get_option(e.orig.buf, "ft") as string
		local name <const> = a.nvim_buf_get_lines(e.input.buf, 0, -1, false)[1]

		local snip = ftSnippets[current_ft][name] or snippets[name]

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
		local code <const> = "return (" .. table.concat(a.nvim_buf_get_lines(e.input.buf, 0, -1, false), " ") .. ")"
		local func <const> = loadstring(code) or stub
		local ok, res = pcall(func) as (boolean, string)
		local data <const> = vim.split(tostring(res or ""), "\n", true)
		a.nvim_buf_set_lines(e.output.buf, 0, -1, false, data)
	end
end

local function step(e: Evaluator)
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
	end
end

function snippet.eval(winId: number) evaluate(evaluators[winId]) end
function snippet.step(winId: number) step(evaluators[winId]) end
function snippet.create(name: string, content: string, defaults: {string})
	local len = 0
	for d in content:gmatch("%%(%d+)") do
		if tonumber(d) > len then
			len = tonumber(d)
		end
	end
	snippets[name] = {
		content = content,
		defaults = defaults or {},
		length = len,
	}
end

function snippet.ftCreate(ft: string|{string}, name: string, content: string, defaults: {string})
	local len = 0
	for d in content:gmatch("%%(%d+)") do
		if tonumber(d) > len then
			len = tonumber(d)
		end
	end
	local snip: Snippet = {
		content = content,
		defaults = defaults or {},
		length = len,
	}
	if ft is string then
		ftSnippets[ft][name] = snip
	else
		for i, v in ipairs(ft) do
			ftSnippets[v][name] = snip
		end
	end
end

function snippet.start()
	createEvaluator("start")
end

return snippet

