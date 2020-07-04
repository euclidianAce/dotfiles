set switchbuf="useopen"
filetype plugin indent on
set belloff=all " stop the stupid beep

" {{{ Some Keybinds
" Disable arrow keys in normal mode
let mapleader=" "
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
set scrolloff=10

"{{{ Text formatting
set linebreak
set nowrap
set formatoptions=lcroj  " each letter corresponds to a text formatting option
                         " from https://vimhelp.org/change.txt.html#fo-table
"}}}
highlight VertSplit cterm=NONE
highlight Folded ctermbg=NONE
highlight FoldColumn ctermbg=NONE

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
