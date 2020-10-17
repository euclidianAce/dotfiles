set runtimepath^=~/.vim runtimepath+=~/.vim/after
filetype plugin indent on
let mapleader=" "
" {{{ Functions
function MyFoldText()
	let line = getline(v:foldstart)
	let br = '{'
	let subline = substitute(line, '\(^"\|\-\-\)\|/\*\|\*/\|'.br.br.br.'\d\=', '', 'g')
	return repeat(' ', indent(v:foldstart)) . repeat('*', v:foldlevel) . substitute(subline, '^\s*', '', '') . repeat('*', v:foldlevel)
endfunction
" }}}
" {{{ Code Editing
" syntax on
syntax off

autocmd BufRead,BufNewFile *.hs set expandtab
autocmd BufRead,BufNewFile *.py set expandtab

" quick shortcut to open pdf of the tex file
function! OpenPDF()
	let _ = system("zathura " . expand("%:r") . ".pdf &")
endfunction
auto FileType tex nnoremap <leader>open :w<CR>:execute OpenPDF()<CR>
" }}}
" {{{ Plugins
" {{{ Install VimPlug if not present
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
" }}}
" {{{ The actual plugins
call plug#begin('~/.vim/plugged')

Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'

Plug 'tpope/vim-endwise'
Plug 'tpope/vim-fugitive'
Plug 'neovim/nvim-lsp'
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }
Plug 'sheerun/vim-polyglot'
Plug 'vimwiki/vimwiki'
Plug 'editorconfig/editorconfig-vim'

" Colors
Plug 'norcalli/nvim-colorizer.lua'
Plug 'dracula/vim', { 'as': 'dracula' }

Plug '~/dev/vim-plugins/nvim-treesitter'
Plug 'nvim-treesitter/playground'

Plug '~/dev/vim-plugins/telescope.nvim'
" My stuff
" Plug '~/dev/vim-plugins/BetterLua.vim'
Plug '~/dev/vim-plugins/exec.vim'
Plug '~/dev/vim-plugins/vim-teal'
call plug#end()
" }}}
" }}}
" {{{ lsp
" default config from :help lsp
nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
"nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>
" except this one
nnoremap <silent> <leader>ldef <cmd>lua vim.lsp.buf.definition()<CR>

" use omni-completion
autocmd Filetype lua setlocal omnifunc=v:lua.vim.lsp.omnifunc
autocmd Filetype [ch] setlocal omnifunc=v:lua.vim.lsp.omnifunc
" }}}
" {{{ set options
set termguicolors
set belloff=all
set guicursor=
set mouse=a
set undodir=$HOME/.vim/undo0
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
set foldtext=MyFoldText()
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
"set spell spelllang=en_us

autocmd BufRead,BufEnter *.wiki setlocal nolist

" }}}
" {{{ Keymaps
nnoremap <Left> <NOP>
nnoremap <Right> <NOP>
nnoremap <Up> <NOP>
nnoremap <Down> <NOP>
" auto complete brackets/etc. only when hitting enter
inoremap {<CR> {}<Esc>i<CR><CR><Esc>kS
inoremap [<CR> []<Esc>i<CR><CR><Esc>kS
inoremap (<CR> ()<Esc>i<CR><CR><Esc>kS

let g:netrw_liststyle = 3
let g:netrw_banner = 0
nnoremap <leader>ff <cmd>let g:netrw_winsize=25<CR><cmd>Lex<CR>
nnoremap <leader>fh <cmd>let g:netrw_winsize=50<CR><cmd>Lex<CR><cmd>NetrwC<CR>
nnoremap <leader>fj <cmd>let g:netrw_winsize=50<CR><cmd>Hex<CR><cmd>NetrwC<CR>
nnoremap <leader>fk <cmd>let g:netrw_winsize=50<CR><cmd>Hex!<CR><cmd>NetrwC<CR>
nnoremap <leader>fl <cmd>let g:netrw_winsize=50<CR><cmd>Lex!<CR><cmd>NetrwC<CR>

nnoremap <leader>fz <cmd>lua require'telescope.builtin'.find_files{}<CR>
nnoremap <leader>g  <cmd>lua require'telescope.builtin'.live_grep()<CR>

tnoremap <silent> <Esc> <C-\><C-n>
inoremap <silent> .shrug ¯\_(ツ)_/¯
inoremap <silent> .Shrug ¯\\\_(ツ)\_/¯
nnoremap <silent> <leader>lua :setlocal sw=3 ts=3 expandtab<CR>:echo "LuaRocks Style Enabled"<CR>
nnoremap <silent> <leader>n :noh<CR>
nnoremap <leader>5 :w<CR>:source %<CR>:echo "Sourced " . expand("%")<CR>

vnoremap <silent> <leader>s :sort<CR>
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
" }}}
" Lua config part
autocmd TextYankPost * lua vim.highlight.on_yank{ higroup = "Search", timeout = 250, on_macro = true }
" lua require'colorizer'.setup()
lua require'euclidian.config'
lua << EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = {"c", "lua", "teal" },
  highlight = {
    enable = true,
  },
}
EOF
