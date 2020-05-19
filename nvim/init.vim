set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vim/vimrc
set guicursor=
" {{{ Plugins
" Install VimPlug if not present
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.vim/plugged')

" Not My stuff
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'
Plug 'itchyny/lightline.vim'
Plug 'neovim/nvim-lsp'
" Syntax
Plug 'vain474/vim-etlua'
Plug 'dpwright/vim-tup'

Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'morhetz/gruvbox'

if has("nvim")
	Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }
endif

" My stuff
Plug '3uclidian/BetterLua.vim'

call plug#end()

let lua_subversion = 4

let g:lightline = {
      \ 'colorscheme': 'darcula',
      \ 'mode_map': {
        \ 'n' : 'Normal',
        \ 'i' : 'Insert',
        \ 'R' : 'Replace',
        \ 'v' : 'Visual',
        \ 'V' : 'Visual Line',
        \ "\<C-v>": 'Visual Block',
        \ 'c' : 'Command',
        \ 's' : 'Select',
        \ 'S' : 'Select Line',
        \ "\<C-s>": 'Select Block',
        \ 't': 'Terminal',
        \ },
      \ }
set bg=dark
colorscheme dracula
" }}}
" {{{ lsp

" default config from :help lsp
nnoremap <silent> gd    <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> <c-]> <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> K     <cmd>lua vim.lsp.buf.hover()<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
nnoremap <silent> 1gD   <cmd>lua vim.lsp.buf.type_definition()<CR>
nnoremap <silent> gr    <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> g0    <cmd>lua vim.lsp.buf.document_symbol()<CR>
nnoremap <silent> gW    <cmd>lua vim.lsp.buf.workspace_symbol()<CR>

" use omni-completion
autocmd Filetype lua setlocal omnifunc=v:lua.vim.lsp.omnifunc
autocmd Filetype c setlocal omnifunc=v:lua.vim.lsp.omnifunc
" }}}
lua require "config"
