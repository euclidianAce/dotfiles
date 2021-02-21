local a <const> = vim.api as {string:function}
local function unCamel(s: string): string
	return (s:gsub("[A-Z]", function(m: string): string
		return "_" .. m:lower()
	end))
end
local function genMetatable<T>(t: T, prefix: string): metatable<T>
	local cache <const>: {number:T} = {}
	return {
		__call = function(_: T, n: number): T
			if not n or n == 0 then
				n = a["nvim_get_current_" .. prefix]() as number
			end
			if not cache[n] then
				cache[n] = setmetatable({ id = n } as T, { __index = t })
			end
			return cache[n]
		end,
		__index = function(_: {string:function}, key: string): function
			local fn <const> = a["nvim_" .. prefix .. "_" .. unCamel(key)]
			return fn and function(self: {string:number}, ...: any): any
				return fn(self.id, ...)
			end
		end,
	}
end

local record MapOpts
	nowait: boolean
	silent: boolean
	script: boolean
	expr: boolean
	unique: boolean
	noremap: boolean
end

local record Buffer
	type Id = number
	id: Id

	call: function<T>(Buffer, function(): T): T
	getOption: function(Buffer, StringOpt): string
	getOption: function(Buffer, BooleanOpt): boolean
	getOption: function(Buffer, NumberOpt): number
	getOption: function(Buffer, string): number | boolean | string
	setOption: function(Buffer, StringOpt, string)
	setOption: function(Buffer, BooleanOpt, boolean)
	setOption: function(Buffer, NumberOpt, number)
	setOption: function(Buffer, string, number | boolean | string)
	setKeymap: function(Buffer, vim.Mode, string, string | function, MapOpts)
	lineCount: function(Buffer): number
	attach: function(Buffer, boolean, {string:any}): boolean
	detach: function(Buffer): boolean
	getLines: function(Buffer, number, number, boolean): {string}
	setLines: function(Buffer, number, number, boolean, {string})
	setText: function(Buffer, number, number, number, number, {string})
	getOffset: function(Buffer, number): number
	getVar: function(Buffer, string): any
	getChangedtick: function(Buffer): number
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
	getMark: function(Buffer, string): {number,number}
	getExtmarkById: function(Buffer, number, number, {string:any}): {number}
	getExtmarks: function(Buffer, number, any, any, {string:any}): {any}
	setExtmark: function(Buffer, number, number, number, {string:any}): number
	delExtmark: function(Buffer, number, number): boolean
	addHighlight: function(Buffer, number, string, number, number, number): number
	clearNamespace: function(Buffer, number, number, number)
	setVirtualText: function(Buffer, number, number, {any}, {string:any}): number
	enum StringOpt
		"buftype"
		"dictionary"
		"path"
		"bufhidden"
		"formatexpr"
		"formatoptions"
		"formatlistpat"
		"formatprg"
		"grepprg"
		"includeexpr"
		"indentexpr"
		"indentkeys"
		"spellfile"
		"iskeyword"
		"spelllang"
		"spelloptions"
		"filetype"
		"keywordprg"
		"lispwords"
		"makeencoding"
		"makeprg"
		"matchpairs"
		"omnifunc"
		"nrformats"
		"backupcopy"
		"cinkeys"
		"include"
		"cinoptions"
		"cinwords"
		"comments"
		"commentstring"
		"completefunc"
		"tags"
		"quoteescape"
		"define"
		"syntax"
		"suffixesadd"
		"spellcapcheck"
		"equalprg"
		"errorformat"
		"fileencoding"
		"fileformat"
		"tagfunc"
		"tagcase"
		"thesaurus"
		"keymap"
		"complete"
	end
	enum BooleanOpt
		"infercase"
		"autoindent"
		"autoread"
		"binary"
		"bomb"
		"cindent"
		"readonly"
		"lisp"
		"modeline"
		"modifiable"
		"modified"
		"copyindent"
		"endofline"
		"smartindent"
		"buflisted"
		"swapfile"
		"fixendofline"
		"preserveindent"
		"undofile"
		"expandtab"
	end
	enum NumberOpt
		"iminsert"
		"imsearch"
		"wrapmargin"
		"channel"
		"undolevels"
		"tabstop"
		"synmaxcol"
		"softtabstop"
		"shiftwidth"
		"scrollback"
		"textwidth"
	end

	metamethod __call: function(Buffer, number): Buffer
end
setmetatable(Buffer, genMetatable(Buffer, "buf"))

local record Window
	type Id = number
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

		win: Id
		relative: Relativity
		anchor: Anchor
		row: number
		col: number
		width: number
		height: number
		bufpos: number
		focusable: boolean
		external: boolean
		style: Style
	end
	getConfig: function(Window): Config
	setConfig: function(Window, Config)
	getOption: function(Window, StringOpt): string
	getOption: function(Window, BooleanOpt): boolean
	getOption: function(Window, NumberOpt): number
	getOption: function(Window, string): number | boolean | string
	setOption: function(Window, StringOpt, string)
	setOption: function(Window, BooleanOpt, boolean)
	setOption: function(Window, NumberOpt, number)
	setOption: function(Window, string, number | boolean | string)
	getBuf: function(Window): number
	setBuf: function(Window, number)
	getCursor: function(Window): {number,number}
	setCursor: function(Window, {number,number})
	getHeight: function(Window): number
	setHeight: function(Window, number)
	getWidth: function(Window): number
	setWidth: function(Window, number)
	getVar: function(Window, string): any
	setVar: function(Window, string, any)
	delVar: function(Window, string)
	getPosition: function(Window): {number,number}
	getTabpage: function(Window): number
	getNumber: function(Window): number
	isValid: function(Window): boolean
	close: function(Window, boolean)
	enum StringOpt
		"fillchars"
		"foldcolumn"
		"foldexpr"
		"foldignore"
		"foldmarker"
		"foldmethod"
		"foldtext"
		"listchars"
		"rightleftcmd"
		"signcolumn"
		"statusline"
		"winhighlight"
		"breakindentopt"
		"colorcolumn"
		"concealcursor"
	end
	enum BooleanOpt
		"cursorcolumn"
		"cursorline"
		"diff"
		"foldenable"
		"linebreak"
		"list"
		"previewwindow"
		"relativenumber"
		"rightleft"
		"scrollbind"
		"spell"
		"winfixheight"
		"winfixwidth"
		"wrap"
		"number"
		"arabic"
		"breakindent"
		"cursorbind"
	end
	enum NumberOpt
		"foldminlines"
		"foldnestmax"
		"numberwidth"
		"scroll"
		"winblend"
		"foldlevel"
		"scrolloff"
		"sidescrolloff"
		"conceallevel"
	end

	metamethod __call: function(Window, number): Window
end
setmetatable(Window, genMetatable(Window, "win"))

local record Tab
	type Id = number
	id: Id

	listWins: function(Tab): {number}
	getVar: function(Tab, string): any
	setVar: function(Tab, string, any)
	delVar: function(Tab, string)
	getWin: function(Tab): number
	getNumber: function(Tab): number
	isValid: function(Tab): boolean

	metamethod __call: function(Tab, number): Tab
end
setmetatable(Tab, genMetatable(Tab, "tabpage"))


return {
	Buffer = Buffer,
	Window = Window,
	Tab = Tab,
	MapOpts = MapOpts,
}

