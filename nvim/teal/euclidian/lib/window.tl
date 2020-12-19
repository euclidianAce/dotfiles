
local a <const> = vim.api

local record window
	type WinId = number
	type BufId = number
end

local record NvimUI
	width: number
	height: number
end

local function getUI(): NvimUI
	return a.nvim_list_uis() as {NvimUI}[1]
end

local function initWin(winOpts: {string:any}): window.WinId, window.BufId
	local buf <const> = a.nvim_create_buf(false, true)
	local win <const> = a.nvim_open_win(buf, true, winOpts)
	return win, buf
end

local function floating(row: number, col: number, wid: number, hei: number): window.WinId, window.BufId
	local win <const>, buf <const> = initWin{
		relative = "editor", style = "minimal", anchor = "NW",
		width = wid, height = hei,
		row = row, col = col,
	}
	return win, buf
end

return {
	t = window,
	new = {
		floating = floating,
	},
}
