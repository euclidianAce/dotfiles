
local cmdf = require("euclidian.lib.util").cmdf
cmdf [[let mapleader = " "]]
cmdf [[set termguicolors]]

cmdf [[packadd packer.nvim]]
require("packer").startup(function()
	use {"wbthomason/packer.nvim", opt = true}

	use "nvim-lua/popup.nvim"
	use "nvim-lua/plenary.nvim"
	use "neovim/nvim-lsp"
	use "tpope/vim-fugitive"

	use "editorconfig/editorconfig-vim"

	use "ziglang/zig.vim"

	use "norcalli/nvim-colorizer.lua"

	use "nvim-treesitter/nvim-treesitter"
	use "nvim-treesitter/playground"

	use "nvim-lua/telescope.nvim"
	use "teal-language/vim-teal"
end)

require("nvim-treesitter.configs").setup{
   ensure_installed = "maintained",
   highlight = { enable = true },
}

require("colorizer").setup()

cmdf [[autocmd BufRead *.tl setlocal ft=teal | setlocal foldmethod=expr | setlocal foldexpr=nvim_treesitter#foldexpr()]]
cmdf [[autocmd TextYankPost * lua vim.highlight.on_yank{ higroup = "STLNormal", timeout = 175, on_macro = true }]]

cmdf [[set undodir=$HOME/.vim/undo]]

local opts = {
	belloff = "all",
	undofile = true,
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
	fillchars = "fold: ",
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
