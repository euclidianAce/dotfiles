filetype plugin indent on
let mapleader=" "
" {{{ Plugins
" TODO: Nov 27 00:56 2020
"       try out packer.nvim, hopefully teal typedefs wont be too hard

" Install VimPlug if not present
if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
  silent !curl -fLo $HOME/.local/share/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" The actual plugins
call plug#begin()
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'

Plug 'tpope/vim-fugitive'
Plug 'neovim/nvim-lsp'
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }
Plug 'editorconfig/editorconfig-vim'

" Colors
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'norcalli/nvim-colorizer.lua'

Plug 'nvim-treesitter/nvim-treesitter'
Plug 'nvim-treesitter/playground'

Plug 'nvim-lua/telescope.nvim'

Plug 'ziglang/zig.vim'

" My stuff
" Plug 'euclidianAce/BetterLua.vim'
Plug 'teal-language/vim-teal'
call plug#end()
" }}}
" {{{ set options
set termguicolors
set belloff=all
" set guicursor=
" set mouse=a
set undodir=$HOME/.vim/undo
set undofile
set noswapfile
set switchbuf=useopen
"set cursorline
set number relativenumber numberwidth=4
set wildmenu " visual autocomplete stuffs
set showcmd " show command being typed
set breakindent " have word wrapping follow indent of wrapped line
set lazyredraw
set splitbelow splitright
set incsearch " highlight results as they're typed
set inccommand=split
set laststatus=2 noshowmode
set modeline
set scrolloff=2
set linebreak
set formatoptions-=t
set formatoptions+=lcroj "see :help fo-table
if !exists("g:started_by_firenvim")
	set showbreak=↪\ 
endif
set listchars+=tab:\ \ \│
set listchars+=eol:↵
set listchars+=trail:✗
set listchars+=space:·
set listchars+=precedes:<
set listchars+=extends:>
set listchars+=nbsp:+
set list
set fillchars+=fold:\ 
set ignorecase smartcase
set gdefault " regex //g by default
set virtualedit=block " allow selection of blocks even when text isnt there
set signcolumn=yes:1

set foldcolumn=3
set foldmethod=marker
" }}}

" auto complete brackets/etc. only when hitting enter
inoremap {<CR> {}<Esc>i<CR><CR><Esc>kS
inoremap (<CR> ()<Esc>i<CR><CR><Esc>kS

tnoremap <silent> <Esc> <C-\><C-n>
nnoremap <silent> <leader>n :noh<CR>
nnoremap <leader>5 :w<CR>:source %<CR>:echo "Sourced " . expand("%")<CR>

autocmd BufRead *.tl setlocal foldmethod=expr | setlocal foldexpr=nvim_treesitter#foldexpr()
autocmd TextYankPost * lua vim.highlight.on_yank{ higroup = "STLNormal", timeout = 250, on_macro = true }

" Lua config part
let g:vimsyn_embed = 'l' " embedded lua highlighting
lua << EOF
require("euclidian.config")
require("nvim-treesitter.configs").setup {
   ensure_installed = "maintained",
   highlight = { enable = true },
}

-- me own language server
function attach_teal_lang_server(buf)
	local client_id = vim.lsp.start_client{
		cmd = {"/home/corey/dev/teal-language-server/run"},
		root_dir = ".",
		callbacks = vim.lsp.callbacks,
	}
	print("attached server to buf: ", buf)
	vim.lsp.buf_attach_client(buf, client_id)
end

require("colorizer").setup()
EOF

" augroup tealLSP
	" au!
	" autocmd BufRead,BufNewFile *.tl call v:lua.attach_teal_lang_server(bufnr())
" augroup END
