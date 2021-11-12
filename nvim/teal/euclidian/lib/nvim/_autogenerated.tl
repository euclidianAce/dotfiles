local record MapOpts
	nowait: boolean
	silent: boolean
	script: boolean
	expr: boolean
	unique: boolean
	noremap: boolean
end
local record Buffer
	type Id = integer
	id: Id
	call: function<Rets...>(Buffer, function(): Rets): Rets
	getOption: function(Buffer, StringOpt): string
	getOption: function(Buffer, BooleanOpt): boolean
	getOption: function(Buffer, IntegerOpt): integer
	getOption: function(Buffer, string): number | boolean | string
	setOption: function(Buffer, StringOpt, string)
	setOption: function(Buffer, BooleanOpt, boolean)
	setOption: function(Buffer, IntegerOpt, integer)
	setOption: function(Buffer, string, integer | boolean | string)
	setKeymap: function(Buffer, vim.Mode, string, string | function, MapOpts)
	lineCount: function(Buffer): integer
	attach: function(Buffer, boolean, {string:any}): boolean
	detach: function(Buffer): boolean
	getLines: function(Buffer, integer, integer, boolean): {string}
	setLines: function(Buffer, integer, integer, boolean, {string})
	setText: function(Buffer, integer, integer, integer, integer, {string})
	getOffset: function(Buffer, integer): integer
	getVar: function(Buffer, string): any
	getChangedtick: function(Buffer): integer
	getKeymap: function(Buffer, string): {{string:any}}
	delKeymap: function(Buffer, string, string)
	getCommands: function(Buffer, {string:any}): {string:any}
	setVar: function(Buffer, string, any)
	delVar: function(Buffer, string)
	getName: function(Buffer): string
	setName: function(Buffer, string)
	isLoaded: function(Buffer): boolean
	delete: function(Buffer, {string:any})
	isValid: function(Buffer): boolean
	delMark: function(Buffer, string): boolean
	setMark: function(Buffer, string, integer, integer, {string:any}): boolean
	getMark: function(Buffer, string): {integer,integer}
	getExtmarkById: function(Buffer, integer, integer, {string:any}): {integer}
	getExtmarks: function(Buffer, integer, any, any, {string:any}): {any}
	setExtmark: function(Buffer, integer, integer, integer, {string:any}): integer
	delExtmark: function(Buffer, integer, integer): boolean
	addHighlight: function(Buffer, integer, string, integer, integer, integer): integer
	clearNamespace: function(Buffer, integer, integer, integer)
	enum BooleanOpt
		"autoindent"
		"autoread"
		"binary"
		"bomb"
		"buflisted"
		"cindent"
		"copyindent"
		"endofline"
		"expandtab"
		"fixendofline"
		"infercase"
		"lisp"
		"modeline"
		"modifiable"
		"modified"
		"preserveindent"
		"readonly"
		"smartindent"
		"swapfile"
		"undofile"
	end
	enum IntegerOpt
		"channel"
		"iminsert"
		"imsearch"
		"scrollback"
		"shiftwidth"
		"softtabstop"
		"synmaxcol"
		"tabstop"
		"textwidth"
		"undolevels"
		"wrapmargin"
	end
	enum StringOpt
		"backupcopy"
		"bufhidden"
		"buftype"
		"cinkeys"
		"cinoptions"
		"cinwords"
		"comments"
		"commentstring"
		"complete"
		"completefunc"
		"define"
		"dictionary"
		"equalprg"
		"errorformat"
		"fileencoding"
		"fileformat"
		"filetype"
		"formatexpr"
		"formatlistpat"
		"formatoptions"
		"formatprg"
		"grepprg"
		"include"
		"includeexpr"
		"indentexpr"
		"indentkeys"
		"iskeyword"
		"keymap"
		"keywordprg"
		"lispwords"
		"makeencoding"
		"makeprg"
		"matchpairs"
		"nrformats"
		"omnifunc"
		"path"
		"quoteescape"
		"spellcapcheck"
		"spellfile"
		"spelllang"
		"spelloptions"
		"suffixesadd"
		"syntax"
		"tagcase"
		"tagfunc"
		"tags"
		"thesaurus"
		"varsofttabstop"
		"vartabstop"
	end
	metamethod __call: function(Buffer, integer): Buffer
	metamethod __eq: function(any, any): boolean
end
local record Window
	type Id = integer
	id: Id
	record Config
		enum Anchor
			"NW" "NE" "SW" "SE"
		end
		enum Style
			"minimal"
		end
		enum Relativity
			"editor" "win" "cursor"
		end
		enum PredefinedBorder
			"none"
			"single"
			"double"
			"shadow"
		end
		type Border = PredefinedBorder | { string | { string, string } }

		win: Id
		relative: Relativity
		anchor: Anchor
		row: integer
		col: integer
		width: integer
		height: integer
		zindex: integer
		bufpos: integer
		focusable: boolean
		external: boolean
		style: Style
		border: Border
	end
	getConfig: function(Window): Config
	setConfig: function(Window, Config)
	getOption: function(Window, StringOpt): string
	getOption: function(Window, BooleanOpt): boolean
	getOption: function(Window, IntegerOpt): integer
	getOption: function(Window, string): integer | boolean | string
	setOption: function(Window, StringOpt, string)
	setOption: function(Window, BooleanOpt, boolean)
	setOption: function(Window, IntegerOpt, integer)
	setOption: function(Window, string, integer | boolean | string)
	getBuf: function(Window): integer
	setBuf: function(Window, integer)
	getCursor: function(Window): {integer,integer}
	setCursor: function(Window, {integer,integer})
	getHeight: function(Window): integer
	setHeight: function(Window, integer)
	getWidth: function(Window): integer
	setWidth: function(Window, integer)
	getVar: function(Window, string): any
	setVar: function(Window, string, any)
	delVar: function(Window, string)
	getPosition: function(Window): {integer,integer}
	getTabpage: function(Window): integer
	getNumber: function(Window): integer
	isValid: function(Window): boolean
	hide: function(Window)
	close: function(Window, boolean)
	call: function(Window, any): any
	enum BooleanOpt
		"arabic"
		"breakindent"
		"cursorbind"
		"cursorcolumn"
		"cursorline"
		"diff"
		"foldenable"
		"linebreak"
		"list"
		"number"
		"previewwindow"
		"relativenumber"
		"rightleft"
		"scrollbind"
		"spell"
		"winfixheight"
		"winfixwidth"
		"wrap"
	end
	enum IntegerOpt
		"conceallevel"
		"foldlevel"
		"foldminlines"
		"foldnestmax"
		"numberwidth"
		"scroll"
		"scrolloff"
		"sidescrolloff"
		"winblend"
	end
	enum StringOpt
		"breakindentopt"
		"colorcolumn"
		"concealcursor"
		"cursorlineopt"
		"fillchars"
		"foldcolumn"
		"foldexpr"
		"foldignore"
		"foldmarker"
		"foldmethod"
		"foldtext"
		"listchars"
		"rightleftcmd"
		"showbreak"
		"signcolumn"
		"statusline"
		"winhighlight"
	end
	metamethod __call: function(Window, integer): Window
	metamethod __eq: function(any, any): boolean
end
local record Tab
	type Id = integer
	id: Id
	listWins: function(Tab): {integer}
	getVar: function(Tab, string): any
	setVar: function(Tab, string, any)
	delVar: function(Tab, string)
	getWin: function(Tab): integer
	getNumber: function(Tab): integer
	isValid: function(Tab): boolean
	metamethod __call: function(Tab, integer): Tab
	metamethod __eq: function(any, any): boolean
end
return {
	Buffer = Buffer,
	Window = Window,
	Tab = Tab,
	MapOpts = MapOpts,
}
