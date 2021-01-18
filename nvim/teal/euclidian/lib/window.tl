
local a <const> = vim.api

local record window
	type WinId = number
	type BufId = number
	record UI
		height: number
		width: number
	end
end

function window.init(winOpts: {string:any}, buf: window.BufId): window.WinId, window.BufId
	if not buf then
		buf = a.nvim_create_buf(false, true)
	end
	local win <const> = a.nvim_open_win(buf, true, winOpts)
	return win, buf
end

-- just grab the first ui
function window.ui(): window.UI
	return a.nvim_list_uis() as {window.UI}[1]
end

function window.floating(col: number, row: number, wid: number, hei: number, buf: window.BufId): window.WinId, window.BufId
	local ui <const> = window.ui()

	if col < 0 then
		col = ui.width + col
	end
	if row < 0 then
		row = ui.height + row
	end

	local win: window.WinId
	win, buf = window.init({
		relative = "editor", style = "minimal", anchor = "NW",
		width = wid, height = hei,
		row = row, col = col,
	}, buf)
	return win, buf
end

return window
