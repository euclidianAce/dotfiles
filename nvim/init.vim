set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vim/vimrc
set guicursor=

set termguicolors
set inccommand=split
" set luarocks style easily
nnoremap <silent> <leader>lua :setlocal sw=3 ts=3 expandtab<CR>:echo "LuaRocks Style Enabled"<CR>
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
nnoremap <silent> <F12> :lua require"statusline".toggleTag"SyntaxViewer"<CR>
