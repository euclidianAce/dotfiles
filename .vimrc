set switchbuf="useopen"
filetype plugin indent on
set belloff=all " stop the stupid beep
packadd! dracula
let g:dracula_italic=0
colorscheme dracula

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
set smartcase " case insensitive search for all lowercase
" otherwise case sensitive

set tags+=tags;$HOME " search for tags files up to home dir
set undofile

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
set foldcolumn=2
set cursorline
set colorcolumn=+1
set incsearch " highlight results as they're typed
set laststatus=2
set noshowmode
set foldmethod=marker	" allow folding

"{{{ Text formatting
set linebreak
set wrap
set textwidth=80
set formatoptions=ltcroj " each letter corresponds to a text formatting option 
                         " from https://vimhelp.org/change.txt.html#fo-table
"}}}
highlight VertSplit cterm=NONE
highlight Folded ctermbg=NONE
highlight FoldColumn ctermbg=NONE
"}}}
" {{{ NERDtree imitation
let g:netrw_liststyle=3 " set tree style to default when viewing directories
let g:netrw_banner=0	" get rid of the banner
"let g:netrw_browse_split=4 " open files in a new tab
"let g:netrw_winsize=20	" have netrw take up 20% of the window

nnoremap <leader>fh :Lex<CR>:NetrwC<CR>
nnoremap <leader>fj :Hex<CR>:NetrwC<CR>
nnoremap <leader>fk :Hex!<CR>:NetrwC<CR>
nnoremap <leader>fl :Lex!<CR>:NetrwC<CR>
set path+=** " fuzzy file search imitation
" }}}
" {{{ Plugins
" My stuff
packadd! statusline
" Other stuff

" }}}
