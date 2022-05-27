local nvim <const> = require("euclidian.lib.nvim")
local ns <const> = nvim.api.createNamespace("euclidian.plug.spacehighlighter")

local function enable(group: string)
	group = group or "TrailingWhitespace"
	nvim.api.setDecorationProvider(ns, {
		on_start = nil,
		on_buf = nil,
		on_win = function(_, _winid: integer, bufnr: integer): boolean
			return not nvim.Buffer(bufnr):getName():match("^term://")
		end,
		on_line = function(_, _winid: integer, bufnr: integer, row: integer): boolean
			local buf <const> = nvim.Buffer(bufnr)

			local ln <const> = buf:getLines(row, row + 1, false)[1];
			local start <const>, finish <const> = ln:match("()%s+()$") as (integer, integer)
			if start ~= finish then
				buf:setExtmark(ns, row, start-1, {
					ephemeral = true,
					end_line = row,
					end_col = finish,
					hl_group = group,
				})
			end

			return true
		end,
		on_end = nil,
	})
end

local function disable()
	nvim.api.setDecorationProvider(ns, {})
end

return {
	enable = enable,
	disable = disable,
}
