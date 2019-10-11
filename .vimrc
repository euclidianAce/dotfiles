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
set formatoptions=tcrq  " each letter corresponds to a text formatting option 
                        " from https://vimhelp.org/change.txt.html#fo-table
                        " t  Auto-wrap text
                        " c  Auto-wrap comments
                        " r  Auto-insert comment header when hitting enter
                        " q  allow formatting of comments with gq
set showcmd		" show command being typed
let g:netrw_liststyle=3 " set tree style to default when viewing directories


syntax enable           " syntax highlighting


auto FileType lua setlocal comments+=:-- " recognize -- as a comment in lua files
" lua function snippet
auto FileType lua nnoremap ,func :read $HOME/.vimsnippets/lua/function<CR>2w
auto FileType lua inoremap ,func <ESC>:read $HOME/.vimsnippets/lua/function<CR>2wciw

" tex begin-end block snippet
auto FileType tex nnoremap ,begin :read $HOME/.vimsnippets/tex/begin-end<CR>:,+2s/BLOCK/
auto FileType tex inoremap ,begin <ESC>:read $HOME/.vimsnippets/tex/begin-end<CR>:,+2s/BLOCK/

" let vim use as many colors as possible
set term=screen-256color
