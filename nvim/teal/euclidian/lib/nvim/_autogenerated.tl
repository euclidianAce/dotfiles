local record CommandArgs
	args: string
	bang: boolean
	line1: integer
	line2: integer
	range: integer
	count: integer
	reg: string
	mods: string
end

local record CommandAttributes
	desc: string
	bang: boolean
	bar: boolean
	register: boolean
	buffer: boolean

	enum ArgumentOpt
		"*" "?" "+"
	end
	nargs: integer | ArgumentOpt

	range: string | integer | boolean
	count: integer | boolean

	enum AddrOpt
		"lines" "arguments" "buffers"
		"loaded_buffers" "windows" "tabs"
		"quickfix" "other"
	end

	addr: AddrOpt

	enum CompleteOpt
		"arglist" "augroup" "buffer" "behave"
		"color" "command" "compiler" "cscope"
		"dir" "environment" "event" "expression"
		"file" "file_in_path" "filetype" "function"
		"help" "highlight" "history" "locale"
		"mapclear" "mapping" "menu" "messages"
		"option" "packadd" "shellcmd" "sign"
		"syntax" "syntime" "tag" "tag_listfiles"
		"user" "var" "lua"
	end

	type CompleteListFunc = function(string, string, integer): {string}
	complete: CompleteOpt | CompleteListFunc
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
	setKeymap: function(Buffer, vim.Mode | {vim.Mode}, string, string | function, vim.keymap.SetOptions)
	delKeymap: function(Buffer, vim.Mode | {vim.Mode}, string, vim.keymap.DelOptions)
	createUserCommand: function(Buffer, string, string | function(CommandArgs), CommandAttributes)
	lineCount: function(Buffer): integer
	attach: function(Buffer, boolean, {string:any}): boolean
	detach: function(Buffer): boolean
	getLines: function(Buffer, integer, integer, boolean): {string}
	setLines: function(Buffer, integer, integer, boolean, {string})
	setText: function(Buffer, integer, integer, integer, integer, {string})
	getText: function(Buffer, integer, integer, integer, integer, {string:any}): {string}
	getOffset: function(Buffer, integer): integer
	getVar: function(Buffer, string): any
	getChangedtick: function(Buffer): integer
	getKeymap: function(Buffer, string): {{string:any}}
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
	delUserCommand: function(Buffer, string)
	getCommands: function(Buffer, {string:any}): {string:any}
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
		"endoffile"
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
		"cinscopedecls"
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
		"lispoptions"
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
		"thesaurusfunc"
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
			"rounded"
			"solid"
			"shadow"
		end
		type Border = PredefinedBorder | { string | { string, string } }
		enum TitlePosition
			"left"
			"center"
			"right"
		end

		win: Id
		relative: Relativity
		anchor: Anchor
		row: integer
		col: integer
		width: integer
		height: integer
		zindex: integer
		bufpos: { integer, integer }
		focusable: boolean
		external: boolean
		style: Style
		border: Border
		noautocmd: boolean
		title: string | {{string, string}}
		title_pos: TitlePosition
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
	setHlNs: function(Window, integer)
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
		"virtualedit"
		"winbar"
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
local record api
	createUserCommand: function(string, string | function(CommandArgs), CommandAttributes)
	record AutocmdOpts
		callback: string | function(string)
		command: string
		pattern: string | {string}
		buffer: integer
		group: string
		once: boolean
		nested: boolean
		desc: string
	end
	createAutocmd: function(string | {string}, AutocmdOpts): integer
	record AugroupOpts
		clear: boolean
	end
	createAugroup: function(string, AugroupOpts): integer
	record DoAutocmdOpts
		buffer: integer
		pattern: string | {string}
		group: string
		modeline: boolean
	end
	doAutocmd: function(string | {string}, DoAutocmdOpts)
	getAutocmds: function({string:any}): {any}
	delAutocmd: function(integer)
	clearAutocmds: function({string:any})
	delAugroupById: function(integer)
	delAugroupByName: function(string)
	execAutocmds: function(any, {string:any})
	parseCmd: function(string, {string:any}): {string:any}
	cmd: function({string:any}, {string:any}): string
	delUserCommand: function(string)
	getCommands: function({string:any}): {string:any}
	createNamespace: function(string): integer
	getNamespaces: function(): {string:any}
	setDecorationProvider: function(integer, {string:any})
	getOptionValue: function(string, {string:any}): any
	setOptionValue: function(string, any, {string:any})
	getAllOptionsInfo: function(): {string:any}
	getOptionInfo: function(string): {string:any}
	setOption: function(string, any)
	getOption: function(string): any
	uiAttach: function(integer, integer, {string:any})
	uiDetach: function()
	uiTryResize: function(integer, integer)
	uiSetOption: function(string, any)
	uiTryResizeGrid: function(integer, integer, integer)
	uiPumSetHeight: function(integer)
	uiPumSetBounds: function(number, number, number, number)
	getHlByName: function(string, boolean): {string:any}
	getHlById: function(integer, boolean): {string:any}
	getHlIdByName: function(string): integer
	setHl: function(integer, string, {string:any})
	setHlNs: function(integer)
	setHlNsFast: function(integer)
	feedkeys: function(string, string, boolean)
	input: function(string): integer
	inputMouse: function(string, string, string, integer, integer, integer)
	replaceTermcodes: function(string, boolean, boolean, boolean): string
	execLua: function(string, {any}): any
	notify: function(string, integer, {string:any}): any
	strwidth: function(string): integer
	listRuntimePaths: function(): {string}
	getRuntimeFile: function(string, boolean): {string}
	setCurrentDir: function(string)
	getCurrentLine: function(): string
	setCurrentLine: function(string)
	delCurrentLine: function()
	getVar: function(string): any
	setVar: function(string, any)
	delVar: function(string)
	getVvar: function(string): any
	setVvar: function(string, any)
	echo: function({any}, boolean, {string:any})
	outWrite: function(string)
	errWrite: function(string)
	errWriteln: function(string)
	listBufs: function(): {integer}
	getCurrentBuf: function(): integer
	setCurrentBuf: function(integer)
	listWins: function(): {integer}
	getCurrentWin: function(): integer
	setCurrentWin: function(integer)
	createBuf: function(boolean, boolean): integer
	openTerm: function(integer, {string:any}): integer
	chanSend: function(integer, string)
	listTabpages: function(): {integer}
	getCurrentTabpage: function(): integer
	setCurrentTabpage: function(integer)
	paste: function(string, boolean, integer): boolean
	put: function({string}, string, boolean, boolean)
	subscribe: function(string)
	unsubscribe: function(string)
	getColorByName: function(string): integer
	getColorMap: function(): {string:any}
	getContext: function({string:any}): {string:any}
	loadContext: function({string:any}): any
	getMode: function(): {string:any}
	getKeymap: function(string): {{string:any}}
	setKeymap: function(string, string, string, {string:any})
	delKeymap: function(string, string)
	getApiInfo: function(): {any}
	setClientInfo: function(string, {string:any}, string, {string:any}, {string:any})
	getChanInfo: function(integer): {string:any}
	listChans: function(): {any}
	callAtomic: function({any}): {any}
	listUis: function(): {any}
	getProcChildren: function(integer): {any}
	getProc: function(integer): any
	selectPopupmenuItem: function(integer, boolean, boolean, {string:any})
	delMark: function(string): boolean
	getMark: function(string, {string:any}): {any}
	evalStatusline: function(string, {string:any}): {string:any}
	exec: function(string, boolean): string
	command: function(string)
	eval: function(string): any
	callFunction: function(string, {any}): any
	callDictFunction: function(any, string, {any}): any
	parseExpression: function(string, string, boolean): {string:any}
	openWin: function(integer, boolean, {string:any}): integer
end
return {
	api = api,
	Buffer = Buffer,
	Window = Window,
	Tab = Tab,
	CommandArgs = CommandArgs,
	CommandAttributes = CommandAttributes,
}
