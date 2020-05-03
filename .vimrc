set switchbuf="useopen"
filetype plugin indent on
set belloff=all " stop the stupid beep

" {{{ Some Keybinds
" Disable arrow keys in normal mode
let mapleader=";"
nnoremap OA <NOP>
nnoremap OB <NOP>
nnoremap OC <NOP>
nnoremap OD <NOP>

" auto match {}
inoremap {<CR> {<CR>+<CR>}<Esc>k$xa
" }}}
"{{{ Code Editing
set ignorecase
set smartcase

set tags+=tags;$HOME " search for tags files up to home dir
set undodir=$HOME/.vim/undo
set undofile
set noswapfile

autocmd BufRead,BufNewFile *.etlua set filetype=html
autocmd BufRead,BufNewFile *.hs set expandtab
autocmd BufRead,BufNewFile *.py set expandtab

" quick shortcut to open pdf of the tex file
function! OpenPDF()
	let _ = system("zathura " . expand("%:r") . ".pdf &")
endfunction
auto FileType tex nnoremap <leader>open :w<CR>:execute OpenPDF()<CR>

" helper function to open a small buffer for stdout and such
function! OutBuffer()
	if bufwinnr("__out__") > 0
		bdelete! __out__
	endif
	:10split __out__
	setlocal buftype=nofile
endfunction

" ;run command executes the current file
function! RunCode()
	" Runs the code and redirects it's output to a buffer
	let out = system("./" . bufname("%") . " 2>&1")
	call OutBuffer()
	call append(0, split(out, '\v\n'))
endfunction
nnoremap <leader>run :execute RunCode()<CR>

"}}}
"{{{ Visuals
set number " relativenumber
set numberwidth=4
set wildmenu " visual autocomplete stuffs
set showcmd " show command being typed
set breakindent	" have word wrapping follow indent of wrapped line
set lazyredraw
set splitbelow
set cursorline
set colorcolumn=70,80
set incsearch " highlight results as they're typed
set laststatus=2
set noshowmode
set foldmethod=marker " allow folding
set foldcolumn=3
set modeline

"{{{ Text formatting
set linebreak
set nowrap
set textwidth=80
set formatoptions=ltcroj " each letter corresponds to a text formatting option 
                         " from https://vimhelp.org/change.txt.html#fo-table
"}}}
highlight VertSplit cterm=NONE
highlight Folded ctermbg=NONE
highlight FoldColumn ctermbg=NONE

" Syntax highlight from tags
autocmd BufRead,BufNewFile *.[ch] let fname = expand('<afile>:p:h') . '/types.vim'
autocmd BufRead,BufNewFile *.[ch] if filereadable(fname)
autocmd BufRead,BufNewFile *.[ch] 	exe 'so ' . fname
autocmd BufRead,BufNewFile *.[ch] endif
"}}}
" {{{ NERDtree imitation
let g:netrw_liststyle=3 " set tree style to default when viewing directories
let g:netrw_banner=0 " get rid of the banner

nnoremap <silent> <leader>ff :let g:netrw_winsize=25<CR>:Lex<CR>
nnoremap <silent> <leader>fh :let g:netrw_winsize=50<CR>:Lex<CR>:NetrwC<CR>
nnoremap <silent> <leader>fj :let g:netrw_winsize=50<CR>:Hex<CR>:NetrwC<CR>
nnoremap <silent> <leader>fk :let g:netrw_winsize=50<CR>:Hex!<CR>:NetrwC<CR>
nnoremap <silent> <leader>fl :let g:netrw_winsize=50<CR>:Lex!<CR>:NetrwC<CR>
set path+=** " fuzzy file search imitation
" }}}
" {{{ Plugins
" My stuff
"packadd! statusline

" Not My stuff
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'
Plug 'itchyny/lightline.vim'
Plug 'vain474/vim-etlua'
Plug 'dracula/vim', { 'as': 'dracula' }
if has("nvim")
	Plug 'glacambre/firenvim', { 'do': { _ -> firenvim#install(0) } }
endif
call plug#end()
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
let g:dracula_italic=0
colorscheme dracula
" }}}
