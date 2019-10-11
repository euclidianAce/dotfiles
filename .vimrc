set number              " line number
set relativenumber      " relative line numbers based on cursor position
set autoindent          " auto indents
set smartindent         " indent for code
set scrolloff=3         " how many rows to keep on screen when cursor moves up or down
set sidescrolloff=5     " how many columns to keep on screen when cursor moves sideways
set cursorline 	        " highlight current line
set wildmenu	        " visual autocomplete stuffs
set lazyredraw	        " redraw screen only when necessary
set title               " let vim set the title of the window
set titleold=Terminal   " reset title after exiting
set formatoptions=tcroq " each letter corresponds to a text formatting option 
                        " from https://vimhelp.org/change.txt.html#fo-table
                        " t  Auto-wrap text
                        " c  Auto-wrap comments
                        " r  Auto-insert comment header when hitting enter
                        " o  Auto-insert comment header when hitting o or O
                        " q  allow formatting of comments with gq

syntax enable           " syntax highlighting
auto FileType lua setlocal comments+=:-- " recognize -- as a comment in lua files

set term=screen-256color
