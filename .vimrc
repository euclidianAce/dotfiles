
"{{{ Code Editing
set autoindent          " auto indents
set smartindent         " indent for code
syntax enable           " syntax highlighting

" tex open, save, and compile command
auto FileType tex nnoremap ;open :w<CR>:!zathura <C-R>=expand("%:p:r").".pdf"<CR> &<CR><CR>
auto FileType tex nnoremap ;comp :w<CR>:!pdflatex <C-R>=expand("%:p")<CR><CR>

" lua run command
" figure out a way to make this only avaliable to executables
auto FileType lua nnoremap ;run :w<CR>:!./<C-R>%<CR>

"}}}

"{{{ Visuals

set number              " line number
set relativenumber      " relative line numbers based on cursor position
set scrolloff=3         " how many rows to keep on screen when cursor moves up or down
set sidescrolloff=5     " how many columns to keep on screen when cursor moves sideways
set cursorline 	        " highlight current line
set wildmenu	        " visual autocomplete stuffs
set lazyredraw	        " redraw screen only when necessary
set showcmd		" show command being typed
set breakindent		" have word wrapping follow indent of wrapped line
let g:netrw_liststyle=3 " set tree style to default when viewing directories
set background=dark
"}}}

"{{{ Text formatting
set linebreak
set wrap
set formatoptions=ltcroj " each letter corresponds to a text formatting option 
                         " from https://vimhelp.org/change.txt.html#fo-table
"}}}

"{{{ Marks
set foldmethod=marker	" allow folding
"}}}

