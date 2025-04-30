local ns <const> = vim.api.nvim_create_namespace("")

local function add_mark(bufnr: vim.BufferId, row: integer, start: integer, finish: integer)
	-- TODO: is nvim_buf_add_highlight better for this?
	vim.api.nvim_buf_set_extmark(bufnr, ns, row, start - 1, {
		ephemeral = true,
		end_line = row,
		end_col = finish,
		hl_group = "EuclidianTrailingWhitespace",
	})
end

local function check_line(bufnr: vim.BufferId, row: integer, line: string, patt: string)
	local start <const>, finish <const> = line:match(patt) as (integer, integer)
	if start ~= finish then
		add_mark(bufnr, row, start, finish)
	end
end

local decoration_provider <const>: vim.DecorationProviderCallbacks = {
	on_win = function(_: string, _winid: vim.WindowId, bufnr: vim.BufferId): boolean
		local name = vim.api.nvim_buf_get_name(bufnr)
		if vim.startswith(name, "term://") then return false end
		local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
		if ft == "fugitive" then return false end
		return true
	end,
	on_line = function(_: string, _winid: vim.WindowId, bufnr: vim.BufferId, row: integer): boolean
		local ln = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
		-- trailing spaces
		check_line(bufnr, row, ln, "()%s+()$")

		-- adjacent spaces and tabs
		check_line(bufnr, row, ln, "() +\t*()\t")
		check_line(bufnr, row, ln, "()\t+ *() ")

		return true
	end,
}

local function enable()
	vim.api.nvim_set_decoration_provider(ns, decoration_provider)
end

local function disable()
	vim.api.nvim_set_decoration_provider(ns, {})
end

return {
	enable = enable,
	disable = disable,
}
