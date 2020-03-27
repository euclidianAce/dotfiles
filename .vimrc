set nocompatible " no compatability with vi
let mapleader=";"
set switchbuf="useopen"
filetype plugin indent on

"{{{ Code Editing
set autoindent          " auto indents
set smartindent         " indent for code syntax enable

" set .etlua to use html syntax
autocmd BufRead,BufNewFile *.etlua set filetype=html

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
nnoremap <leader>run :w<CR>:execute RunCode()<CR>

function! LuaCheck()
	let out = system("luacheck " . bufname("%") . " --no-color 2>&1")
	call OutBuffer()
	call append(0, split(out, '\v\n'))
endfunction
auto FileType lua nnoremap <leader>lc :w<CR>:execute LuaCheck()<CR>

"}}}
"{{{ Visuals
set number relativenumber
set numberwidth=6
"set cursorline
set scrolloff=3         " how many rows to keep on screen when cursor moves up or down
set sidescrolloff=5     " how many columns to keep on screen when cursor moves sideways
set wildmenu	        " visual autocomplete stuffs
set showcmd		" show command being typed
set breakindent		" have word wrapping follow indent of wrapped line
set splitbelow
"colorscheme dracula
colorscheme peachpuff
"}}}
"{{{ Custom Tabline 
" see :help statusline for details about some stuff
function! GetTabline()
	let s = '%#TabLineFill# '
	let tabpageNumber = tabpagenr()
	let i = 1
	while i <= tabpagenr('$')
		" the buffers in the current tabpage
		let bufferList = tabpagebuflist(i)
		" the number of windows in the current tabpage
		let tabpageWindowNumber = tabpagewinnr(i)
		" Clickable label
		let s .= '%' . i . 'T'
		" set highlight group
		let s .= (i == tabpageNumber ? '%1*' : '%2*')
		let windowNumber = tabpagewinnr(i, '$')
		" Highlight color
		let s .= (i == tabpageNumber ? '%#TabLineSel#' : '%#TabLine#')
		let s .= ' '
		" The actual tab number
		let s .= '[' . i . '] '
		let bufferNumber = bufferList[windowNumber - 1]
		let file = bufname(bufferNumber)
		let bufferType = getbufvar(bufferNumber, 'buftype')
		if bufferType == 'nofile'
			if file =~ '\/.'
				let file = substitute(file, '.*\/\ze.', '', '')
			endif
		else
			let file = fnamemodify(file, ':p:t')
		endif
		if file == ''
			let file = '[Unnamed]'
		endif
		let s .= file
		" Add window number if there are multiple windows
		if tabpagewinnr(i, '$') > 1
			let s .= ' ('
			let s .= (tabpagewinnr(i, '$') > 1 ? windowNumber : '')
			let s .= ')'
		endif
		let s .= ' '
		" modified flag
		let s .= (i == tabpageNumber ? '%m' : '') 
		if i < tabpagenr('$')
			let s .= '%#TabLineFill# '
		endif
		" Loopy doop
		let i = i + 1
	endwhile
	let s .= '%T%#TabLineFill#%='
	return s
endfunction
set tabline=%!GetTabline()
" }}}
" {{{ Custom Status Line
set laststatus=2
set noshowmode
hi StatusLine guibg=#2c2c2c guifg=#5f5f5f
function! ModeColor(mode)
	if a:mode == 'n'
		hi StatusLineColor ctermfg=0 ctermbg=110 guibg=#80a1d4 guifg=#000000
	elseif a:mode == 'i'
		hi StatusLineColor ctermfg=0 ctermbg=78 guibg=#36d495 guifg=#000000
	elseif a:mode == 'R'
		hi StatusLineColor ctermfg=0 ctermbg=167 guibg=#dd403a guifg=#000000
	elseif a:mode == 'v' || a:mode == 'V' || a:mode == ''
		hi StatusLineColor ctermfg=0 ctermbg=221 guibg=#f5cb5c guifg=#000000
	elseif a:mode == 'c'
		hi StatusLineColor ctermfg=0 ctermbg=185 guibg=#3f3f3f guifg=#000000
	elseif a:mode == 't'
		hi StatusLineColor ctermfg=0 ctermbg=185 guibg=#3f3f3f guifg=#000000
	endif
	return ''
endfunction
let g:currMode = {
	\ 'n': 'Normal',
	\ 'i': 'Insert',
	\ 'R': 'Replace',
	\ 'v': 'Visual',
	\ 'V': 'Visual Line',
	\ '': 'Visual Block',
	\ 'c': 'Command',
	\ 't': 'Terminal',
	\ }
hi LineNumber ctermfg=255 ctermbg=234 guibg=#101010 guifg=#9F9F9F
hi BufferNumber ctermfg=255 ctermbg=235 guibg=#202020
hi FileName ctermfg=255 ctermbg=236 guibg=#303030
hi ActiveLine ctermfg=255 ctermbg=238
hi NonActiveLine ctermfg=255 ctermbg=235
function! GetStatusline()
	let s = ''
	let active = g:statusline_winid == win_getid(winnr())
	if active
		let s .= '%{ModeColor(mode())}%#StatusLineColor# %{currMode[mode()]} '
	endif
	let s .= '%#BufferNumber# %n '
	let s .= '%#FileName# %f %y%r%h%w%m '
	if active
		let s .= '%#ActiveLine#'
	else
		let s .= '%#NonActiveLine#'
	end
	let s .= '%='
	let s .= '%#LineNumber# %l/%L:%c %3p%%  '

	return s
endfunction
set statusline=%!GetStatusline()
" }}}
" {{{ NERDtree imitation
let g:netrw_liststyle=3 " set tree style to default when viewing directories
let g:netrw_banner=0	" get rid of the banner
let g:netrw_browse_split=3 " open files in a new tab
let g:netrw_winsize=20	" have netrw take up 20% of the window
nnoremap <leader>f :Vex<CR>
set path+=** " fuzzy file search imitation
" }}}
"{{{ Text formatting
set linebreak
set wrap
set formatoptions=ltcroj " each letter corresponds to a text formatting option 
                         " from https://vimhelp.org/change.txt.html#fo-table
"}}}
"{{{ Folding
set foldmethod=marker	" allow folding
"}}}
