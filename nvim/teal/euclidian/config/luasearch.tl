
local nvim <const> = require("euclidian.lib.nvim")
local dialog <const> = require("euclidian.lib.dialog")

local function gfind(str: string, patt: string): function(): integer, integer, {string}
	local idx = 0
	local a, b: integer, integer
	return function(): integer, integer, {string}
		local res = { string.find(str, patt, idx) }
		a = table.remove(res, 1) as integer
		b = table.remove(res, 1) as integer
		if b then
			idx = b + 1
		end
		return a, b, #res > 0 and res as {string} or nil
	end
end

local function findMatches(buf: nvim.Buffer, patt: string): function(): integer, integer, integer, string, boolean
	return coroutine.wrap(function()
		for lnum, ln in ipairs(buf:getLines(0, -1, false)) do
			for s, e, matches in gfind(ln, patt) do
				coroutine.yield(lnum, s, e, ln:sub(s, e), false)
				if matches then
					for _, m in ipairs(matches) do
						local start <const>, finish <const> = string.find(ln, m, s, true)
						coroutine.yield(lnum, start, finish, m, true)
					end
				end
			end
		end
	end) as function(): integer, integer, integer, string, boolean
end

local function exec()
	local d <const> = dialog.new{
		wid = 30, hei = 1,
		row = -10, col = 0.5,

		interactive = true,
	}
	local buf <const> = d.buf

	local ns <const> = vim.api.nvim_create_namespace("luasearch")
	nvim.autocmd({"BufDelete", "BufHidden"}, nil, function() buf:clearNamespace(ns, 0, -1) end, { buffer = d.buf.id })
	buf:attach(false, {
		on_lines = function()
			buf:clearNamespace(ns, 0, -1)
			local patt <const> = d:getLine(1)
			if patt == "" then return end
			-- TODO
			-- local replace <const> = d:getLine(2)
			-- local shouldReplace <const> = replace and #replace > 0
			pcall(function()
				for lnum, s, e, _match, isCapture in findMatches(buf, patt) do
					buf:setExtmark(ns, lnum - 1, s - 1, {
						end_line = lnum - 1,
						end_col = e,
						hl_group = isCapture and "STLNormal" or "STLInsert",
					})
				end
			end)
			d:fitTextPadded(2, 0, 30, nil, nil, 2):centerHorizontal()
		end
	})
	d:setModifiable(true)
end

return exec
