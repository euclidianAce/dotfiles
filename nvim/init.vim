filetype plugin indent on
let mapleader=" "
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

Plug 'tpope/vim-endwise'
Plug 'tpope/vim-fugitive'
Plug 'neovim/nvim-lsp'
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }
Plug 'editorconfig/editorconfig-vim'

" Colors
Plug 'dracula/vim', { 'as': 'dracula' }

Plug 'nvim-treesitter/nvim-treesitter'
Plug 'nvim-treesitter/playground'

Plug 'nvim-lua/telescope.nvim'
" My stuff
Plug 'euclidianAce/BetterLua.vim'
Plug 'teal-language/vim-teal'
call plug#end()

" {{{ set options
set termguicolors
set belloff=all
set guicursor=
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
set foldmethod=marker
set foldcolumn=3
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

" }}}
" {{{ Keymaps
" auto complete brackets/etc. only when hitting enter
inoremap {<CR> {}<Esc>i<CR><CR><Esc>kS
inoremap [<CR> []<Esc>i<CR><CR><Esc>kS
inoremap (<CR> ()<Esc>i<CR><CR><Esc>kS

let g:netrw_liststyle = 3
let g:netrw_banner = 0

tnoremap <silent> <Esc> <C-\><C-n>
inoremap <silent> .shrug ¯\_(ツ)_/¯
inoremap <silent> .Shrug ¯\\\_(ツ)\_/¯
nnoremap <silent> <leader>n :noh<CR>
nnoremap <leader>5 :w<CR>:source %<CR>:echo "Sourced " . expand("%")<CR>

" }}}
" {{{ colors
colorscheme dracula

hi! link Folded Comment
hi! link FoldColumn Comment
hi! link SignColumn Comment
hi! link Error DraculaRedInverse
hi! link TSParameter DraculaOrangeItalic
" Dracula Cyan Bold
hi clear TODO
hi! Todo guifg=#8BE9FD gui=bold
hi! link Search mySTLn
" }}}
" Lua config part
autocmd TextYankPost * lua vim.highlight.on_yank{ higroup = "mySTLn", timeout = 250, on_macro = true }
lua require'euclidian.config'
lua << EOF
require'nvim-treesitter.configs'.setup {
   ensure_installed = { "teal", "c" },
   highlight = { enable = true },
}
EOF
