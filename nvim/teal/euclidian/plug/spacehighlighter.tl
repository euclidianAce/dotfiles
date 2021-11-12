local nvim <const> = require("euclidian.lib.nvim")
local ns <const> = vim.api.nvim_create_namespace("euclidian.plug.spacehighlighter")

local function enable()
	vim.api.nvim_set_decoration_provider(ns, {
		on_start = nil,
		on_buf = nil,
		on_win = function(): boolean
			return true
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
					hl_group = "Error",
				})
			end

			return true
		end,
		on_end = nil,
	})
end

local function disable()
	vim.api.nvim_set_decoration_provider(ns, {})
end

return {
	enable = enable,
	disable = disable,
}
