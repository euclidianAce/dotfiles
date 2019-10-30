
"{{{Code Editing

set autoindent          " auto indents
set smartindent         " indent for code
syntax enable           " syntax highlighting


auto FileType lua setlocal comments+=:-- " recognize -- as a comment in lua files

" tex save and compile command
auto FileType tex nnoremap ;open :w<CR>:!zathura <C-R>% <CR>
auto FileType tex nnoremap ;comp :w<CR>:!pdflatex <C-R>% <CR><CR>

"}}}

"{{{Visuals

set number              " line number
set relativenumber      " relative line numbers based on cursor position
set scrolloff=3         " how many rows to keep on screen when cursor moves up or down
set sidescrolloff=5     " how many columns to keep on screen when cursor moves sideways
set cursorline 	        " highlight current line
set wildmenu	        " visual autocomplete stuffs
set lazyredraw	        " redraw screen only when necessary
set showcmd		" show command being typed
set nowrap		" dont wrap text
let g:netrw_liststyle=3 " set tree style to default when viewing directories
set background=dark
" let vim use as many colors as possible
set term=screen-256color

"}}}

"{{{Text formatting

set formatoptions=toj	" each letter corresponds to a text formatting option 
                        " from https://vimhelp.org/change.txt.html#fo-table
"}}}

"{{{ Marks
set foldmethod=marker	" allow folding
"}}}

