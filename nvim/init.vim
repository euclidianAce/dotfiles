set runtimepath^=~/.vim runtimepath+=~/.vim/after
set guicursor=
set termguicolors

set switchbuf="useopen"
filetype plugin indent on
set belloff=all " stop the stupid beep

" {{{ Some Keybinds
let mapleader=" "
" Disable arrow keys in normal mode
nnoremap <Left> <NOP>
nnoremap <Right> <NOP>
nnoremap <Up> <NOP>
nnoremap <Down> <NOP>

" auto match {} only when hitting enter
inoremap {<CR> {<CR>+<CR>}<Esc>k$xa
" }}}
"{{{ Code Editing
syntax on
set ignorecase
set smartcase

set tags+=tags;$HOME " search for tags files up to home dir
set undodir=$HOME/.vim/undo
set undofile
set noswapfile

autocmd BufRead,BufNewFile *.hs set expandtab
autocmd BufRead,BufNewFile *.py set expandtab

" quick shortcut to open pdf of the tex file
function! OpenPDF()
	let _ = system("zathura " . expand("%:r") . ".pdf &")
endfunction
auto FileType tex nnoremap <leader>open :w<CR>:execute OpenPDF()<CR>

"}}}
"{{{ Visuals
set number relativenumber
set numberwidth=4
set wildmenu " visual autocomplete stuffs
set showcmd " show command being typed
set breakindent " have word wrapping follow indent of wrapped line
set lazyredraw
set splitbelow
set splitright
set colorcolumn=70,80
set incsearch " highlight results as they're typed
set inccommand=split
set laststatus=2
set noshowmode
set foldmethod=marker " allow folding
set foldcolumn=3
set modeline
set scrolloff=10
set linebreak
set nowrap
set formatoptions=lcroj  " each letter corresponds to a text formatting option
                         " from https://vimhelp.org/change.txt.html#fo-table
set list listchars=tab:⭾\ ,eol:↵,trail:✗

"}}}
" {{{ NERDtree imitation
let g:netrw_liststyle=3 " set tree style to default when viewing directories
let g:netrw_banner=0 " get rid of the banner

nnoremap <silent> <leader>ff :let g:netrw_winsize=25<CR>:Lex<CR>
nnoremap <silent> <leader>fh :let g:netrw_winsize=50<CR>:Lex<CR>:NetrwC<CR>
nnoremap <silent> <leader>fj :let g:netrw_winsize=50<CR>:Hex<CR>:NetrwC<CR>
nnoremap <silent> <leader>fk :let g:netrw_winsize=50<CR>:Hex!<CR>:NetrwC<CR>
nnoremap <silent> <leader>fl :let g:netrw_winsize=50<CR>:Lex!<CR>:NetrwC<CR>
" }}}
" {{{ Plugins
" Install VimPlug if not present
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
" {{{
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'
Plug 'neovim/nvim-lsp'
" Plug 'nvim-treesitter/nvim-treesitter'

" Syntax
Plug 'dpwright/vim-tup'
Plug 'teal-language/vim-teal'
let g:teal_check_only = 1

Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

" Colors
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'morhetz/gruvbox'

" My stuff
Plug '3uclidian/BetterLua.vim'
Plug '3uclidian/exec.vim'
" }}}
call plug#end()

" fzf
nnoremap <leader>fz :FZF<CR>
nnoremap <leader>rg :Rg<CR>
let g:fzf_preview_window = "right:60%"

set bg=dark
colorscheme dracula
" }}}
" {{{ lsp

" default config from :help lsp
nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>
" nnoremap <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>

" use omni-completion
autocmd Filetype lua setlocal omnifunc=v:lua.vim.lsp.omnifunc
autocmd Filetype [ch] setlocal omnifunc=v:lua.vim.lsp.omnifunc
" }}}

lua require "config"
lua require "statusline"
nnoremap <silent> <F12> :lua require'statusline'.toggleTag'Debugging'<CR>

" set luarocks style easily
nnoremap <silent> <leader>lua :setlocal sw=3 ts=3 expandtab<CR>:echo "LuaRocks Style Enabled"<CR>
