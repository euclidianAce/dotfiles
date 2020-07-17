set runtimepath^=~/.vim runtimepath+=~/.vim/after

filetype plugin indent on

let mapleader=" "
"{{{ Code Editing
syntax on

autocmd BufRead,BufNewFile *.hs set expandtab
autocmd BufRead,BufNewFile *.py set expandtab

" quick shortcut to open pdf of the tex file
function! OpenPDF()
	let _ = system("zathura " . expand("%:r") . ".pdf &")
endfunction
auto FileType tex nnoremap <leader>open :w<CR>:execute OpenPDF()<CR>
"}}}
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
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'
Plug 'neovim/nvim-lsp'
Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
Plug 'dpwright/vim-tup'
Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }

" Colors
Plug 'dracula/vim', { 'as': 'dracula' }

" My stuff
Plug 'euclidianAce/BetterLua.vim'
Plug 'euclidianAce/exec.vim'
Plug 'euclidianAce/teal-interactive.nvim'
Plug 'teal-language/vim-teal'
call plug#end()
" }}}
" fzf
nnoremap <leader>fz :FZF<CR>
nnoremap <leader>rg :Rg<CR>
let g:fzf_preview_window = "right:60%"
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
" {{{ Keymaps
nnoremap <Left> <NOP>
nnoremap <Right> <NOP>
nnoremap <Up> <NOP>
nnoremap <Down> <NOP>
inoremap {<CR> {}<Esc>i<CR><CR><Esc>kS

let g:netrw_liststyle = 3
let g:netrw_banner = 0
nnoremap <leader>ff :let g:netrw_winsize=25<CR>:Lex<CR>
nnoremap <leader>fh :let g:netrw_winsize=50<CR>:Lex<CR>:NetrwC<CR>
nnoremap <leader>fj :let g:netrw_winsize=50<CR>:Hex<CR>:NetrwC<CR>
nnoremap <leader>fk :let g:netrw_winsize=50<CR>:Hex!<CR>:NetrwC<CR>
nnoremap <leader>fl :let g:netrw_winsize=50<CR>:Lex!<CR>:NetrwC<CR>
" }}}
" {{{ set
set termguicolors belloff=all
set guicursor=
set undodir=$HOME/.vim/undo
set undofile
set noswapfile
set switchbuf=useopen
set number relativenumber numberwidth=4
set wildmenu " visual autocomplete stuffs
set showcmd " show command being typed
set breakindent " have word wrapping follow indent of wrapped line
set lazyredraw
set splitbelow splitright
set colorcolumn=70,80
set incsearch " highlight results as they're typed
set inccommand=split
set laststatus=2 noshowmode
set foldmethod=marker foldcolumn=3
set modeline
set scrolloff=10
set linebreak
set formatoptions+=lcroj "see :help fo-table
set list listchars=tab:⭾\ ,eol:↵,trail:✗
set ignorecase smartcase
set virtualedit=block " allow selection of blocks even when text isnt there
" }}}

lua require "config"
lua require "statusline"
nnoremap <silent> <F12> :lua require'statusline'.toggleTag'Debugging'<CR>
tnoremap <silent> <Esc> <C-\><C-n>
inoremap <silent> .shrug ¯\_(ツ)_/¯

auto FileType teal autocmd BufWrite *.tl lua require'teal-type-checker'.getTypeChecker():annotateTypeErrors()
nnoremap <silent> <leader>t :lua require'teal-type-checker'.getTypeChecker():annotateTypeErrors()<CR>

colorscheme dracula

hi! link Folded Comment
hi! link FoldColumn Comment
hi! link SignColumn Comment

" set luarocks style easily
nnoremap <silent> <leader>lua :setlocal sw=3 ts=3 expandtab<CR>:echo "LuaRocks Style Enabled"<CR>
