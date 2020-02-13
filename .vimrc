set nocompatible " no compatability with vi

"{{{ Code Editing
"set autoindent          " auto indents
"set smartindent         " indent for code
syntax enable           " syntax highlighting

" set .etlua to use html syntax
autocmd BufRead,BufNewFile *.etlua set filetype=html

" quick shortcut to open pdf of the tex file
auto FileType tex nnoremap ;open :w<CR>:!zathura <C-R>=expand("%:p:r").".pdf"<CR> &<CR><CR>

" lua run command
" figure out a way to make this only avaliable to executables
function! RunCode()
	" generates a tmp file and executes the current file
	" while redirecting its output to the tmp file
	let out = system("./" . bufname("%") . " 2>&1")

	:10split __out__
	normal! ggdG
	setlocal buftype=nofile

	call append(0, split(out, '\v\n'))
endfunction
nnoremap ;run :w<CR>:execute RunCode()<CR>
set splitbelow
"}}}
"{{{ Visuals
set number              " line number
set relativenumber      " relative line numbers based on cursor position
set scrolloff=3         " how many rows to keep on screen when cursor moves up or down
set sidescrolloff=5     " how many columns to keep on screen when cursor moves sideways
set wildmenu	        " visual autocomplete stuffs
set lazyredraw	        " redraw screen only when necessary
set showcmd		" show command being typed
set breakindent		" have word wrapping follow indent of wrapped line
set background=dark

colorscheme peachpuff

" Custom Tabline, see :help statusline for details about some stuff
function! GetTabline()
	let s = '%#TabLineFill#%='
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

"}}}
" {{{ NERDtree imitation
let g:netrw_liststyle=3 " set tree style to default when viewing directories
let g:netrw_banner=0	" get rid of the banner
let g:netrw_browse_split=3 " open files in a new tab
let g:netrw_winsize=20	" have netrw take up 20% of the window
" }}}
"{{{ Text formatting
set linebreak
set wrap
set formatoptions=ltcroj " each letter corresponds to a text formatting option 
                         " from https://vimhelp.org/change.txt.html#fo-table
"}}}
"{{{ Marks
set foldmethod=marker	" allow folding
"}}}
" {{{ Navigation
noremap <Up> <nop>
noremap <Down> <nop>
noremap <Left> <nop>
noremap <Right> <nop>
noremap! <Up> <nop>
noremap! <Down> <nop>
noremap! <Left> <nop>
noremap! <Right> <nop>
" }}}
