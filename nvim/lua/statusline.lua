local M = {}

local cmd = vim.api.nvim_command

local modeMap = {
	n = 'Normal',
	i = 'Insert',
	R = 'Replace',
	v = 'Visual',
	V = 'Visual Line',
	[""] = 'Visual Block',
	c = 'Command',
	s = 'Select',
	S = 'Select Line',
	[""] = 'Select Block',
	t = 'Terminal',
}


local inactiveLine = " %#Comment#[buf: %n] %#Identifier#[%.30f]%#Comment# %y%r%h%w%m %#User1#%=%#Comment# %l/%L:%c %3p%% %#Normal#  "
-- the luaeval is kinda janky here, but it seems to be the only option to put an expression here
-- as v:lua.require("statusline").getModeText() doesn't work here
local activeLine = [=[%#Special# [%{luaeval("require'statusline'.getModeText()")}]]=] .. (inactiveLine:gsub("User1", "User2"))
cmd "hi! User1 guibg=#1F1F1F"
cmd "hi! link User2 Visual"

function M.setInactive()
	vim.api.nvim_win_set_option(0, "statusline", inactiveLine)
end

function M.setActive()
	vim.api.nvim_win_set_option(0, "statusline", activeLine)
end

function M.getModeText()
	return modeMap[vim.fn.mode()]
end

-- this feels wrong to do with just a bunch of command calls
cmd "augroup customstatus"
cmd 	"autocmd!"
cmd	"autocmd WinEnter * lua require('statusline').setActive()"
cmd	"autocmd BufWinEnter * lua require('statusline').setActive()"
cmd	"autocmd WinLeave * lua require('statusline').setInactive()"
cmd "augroup END"
M.setActive()

return M
