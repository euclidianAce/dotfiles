
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
	return (a.nvim_list_uis() as {window.UI})[1]
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

local floor <const>, max <const>, min <const>
	= math.floor, math.max, math.min
local function getWinSize(wid: number, hei: number): number, number, number, number
	local ui <const> = window.ui()

	local minWid <const> = floor(ui.width * .25)
	local minHei <const> = floor(ui.height * .25)

	local maxWid <const> = floor(ui.width * .90)
	local maxHei <const> = floor(ui.height * .90)

	wid = min(max(minWid, wid), maxWid)
	hei = min(max(minHei, hei), maxHei)

	return (ui.width - wid) // 2, (ui.height - hei) // 2, wid, hei
end

function window.centeredFloat(wid: number, hei: number, buf: window.BufId): window.WinId, window.BufId
	local col <const>, row <const>, actualWid <const>, actualHei <const>
		= getWinSize(wid, hei)

	local win: window.WinId
	win, buf = window.init({
		relative = "editor", style = "minimal", anchor = "NW",
		width = actualWid, height = actualHei,
		row = row, col = col,
	}, buf)
	return win, buf
end

return window

