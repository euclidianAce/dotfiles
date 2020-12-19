
local cmdf = require("euclidian.lib.util").cmdf
cmdf [[let mapleader = " "]]
cmdf [[set termguicolors]]
cmdf [[filetype indent on]]

require("euclidian.lib.package-manager").enableSet("World")

require("nvim-treesitter.configs").setup{
	ensure_installed = "maintained",
	highlight = { enable = true },
}

require("colorizer").setup()

cmdf [[syntax enable]]
-- lua autocmds would be nice
cmdf [[autocmd BufReadPre,BufRead,BufNewFile *.tl,*.lua syntax off | setlocal foldmethod=expr | setlocal foldexpr=nvim_treesitter#foldexpr() | setlocal sw=3 ts=3]]
cmdf [[autocmd BufReadPre,BufRead,BufNewFile *.c,*.h setlocal sw=4 ts=4]]
cmdf [[autocmd BufRead *.adb setlocal sw=3 ts=3]]
cmdf [[autocmd TextYankPost * lua vim.highlight.on_yank{ higroup = "STLNormal", timeout = 175, on_macro = true }]]

cmdf [[set undofile]]
cmdf [[set undodir=$HOME/.vim/undo]]

local opts = {
	mouse = "a",
	belloff = "all",
	swapfile = false,
	switchbuf = "useopen",
	wildmenu = true,
	showcmd = true,
	breakindent = true,
	lazyredraw = true,
	splitbelow = true,
	splitright = true,
	incsearch = true,
	showmode = false,
	modeline = true,
	linebreak = true,
	ignorecase = true,
	smartcase = true,
	gdefault = true,
	listchars = "tab:  │,eol:↵,trail:✗,space:·,precedes:<,extends:>,nbsp:+",
	fillchars = "fold: ,vert: ",
	inccommand = "split",
	laststatus = 2,
	scrolloff = 2,
	formatoptions = "lcroj",
	virtualedit = "block",
	foldmethod = "marker",
}

local winOpts = {
	list = true,
	signcolumn = "yes:1",
	foldcolumn = "3",
	numberwidth = 4,
	number = true,
	relativenumber = true,
}

for opt, val in pairs(opts) do
	vim.o[opt] = val
end
for opt, val in pairs(winOpts) do
	vim.wo[opt] = val
end

require("euclidian.config")

-- global function attach_teal_lang_server(buf)
-- 	local client_id = vim.lsp.start_client{
-- 		cmd = {"/home/corey/dev/teal-language-server/run"},
-- 		root_dir = ".",
-- 		handlers = vim.lsp.handlers,
-- 	}
-- 	print("attached teal-language-server to buf: ", buf)
-- 	vim.lsp.buf_attach_client(buf, client_id)
-- end
