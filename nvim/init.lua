
local cmdf = require("euclidian.lib.util").cmdf
cmdf [[let mapleader = " "]]
cmdf [[set termguicolors]]
cmdf [[filetype indent on]]

require("euclidian.lib.package-manager")
require("euclidian.lib.package-manager.loader").enableSet("World")

require("nvim-treesitter.configs").setup{
	ensure_installed = { "teal" },
	highlight = { enable = { "teal" } },
}

require("colorizer").setup()

cmdf [[syntax enable]]
-- lua autocmds would be nice
cmdf [[autocmd BufReadPre,BufRead,BufNewFile *.tl,*.lua syntax off | setlocal foldmethod=expr | setlocal foldexpr=nvim_treesitter#foldexpr() | setlocal sw=3 ts=3]]
cmdf [[autocmd BufReadPre,BufRead,BufNewFile *.c,*.h,*.cpp setlocal sw=4 ts=4]]
cmdf [[autocmd TextYankPost * lua vim.highlight.on_yank{ higroup = "STLNormal", timeout = 175, on_macro = true }]]
cmdf [[autocmd TermOpen * setlocal nonumber norelativenumber foldcolumn=0 signcolumn=no]]
cmdf [[autocmd Filetype lua setlocal omnifunc=v:lua.vim.lsp.omnifunc]]
cmdf [[autocmd Filetype *.c,*.cpp,*.h,*.hpp setlocal omnifunc=v:lua.vim.lsp.omnifunc]]

cmdf [[set undofile]]
cmdf [[set undodir=$HOME/.vim/undo]]

local function set(t, options)
	for opt, val in pairs(options) do
		t[opt] = val
	end
end

set(vim.g, {
	netrw_liststyle = 3,
	netrw_banner = 0,
})

set(vim.o, {
	mouse = "a",
	guicursor = "",
	belloff = "all",
	swapfile = false,
	switchbuf = "useopen",
	wildmenu = true,
	showcmd = true,
	breakindent = true,
	lazyredraw = true,
	splitbelow = true,
	splitright = true,
	incsearch = true,
	showmode = false,
	modeline = true,
	linebreak = true,
	ignorecase = true,
	smartcase = true,
	gdefault = true,
	listchars = "tab:   ,trail:✗,space:·,precedes:<,extends:>,nbsp:+",
	fillchars = "fold: ,vert: ",
	inccommand = "split",
	laststatus = 2,
	scrolloff = 2,
	formatoptions = "lroj",
	virtualedit = "block",
	foldmethod = "marker",
})

set(vim.wo, {
	list = true,
	signcolumn = "yes:1",
	foldcolumn = "3",
	numberwidth = 4,
	number = true,
	relativenumber = true,
})

function attach_teal_lang_server(buf)
	local client_id = vim.lsp.start_client{
		cmd = { "/home/corey/dev/teal-language-server/run" },
		root_dir = ".",
		handlers = vim.lsp.handlers,
	}
	vim.lsp.buf_attach_client(buf, client_id)
	print("attached teal-language-server to buf: ", buf)
end

local lsp = require("lspconfig")
local lspSettings = {
	sumneko_lua = { settings = { Lua = {
		runtime = { version = "Lua 5.4" },
		diagnostics = {
			globals = {
				-- Vim api
				"vim",

				-- Tupfile.lua
				"tup",

				-- Busted
				"it", "describe", "setup", "teardown", "pending", "finally",

				-- Computercraft
				"turtle", "fs", "shell",

				-- awesomewm
				"awesome", "screen", "mouse", "client", "root",
			},
			disable = {
				"empty-block",
				"undefined-global",
				"unused-function",
			},
		},
	} } },
	clangd = {},
}

for server, settings in pairs(lspSettings) do
	lsp[server].setup(settings)
end

function req(lib)
	package.loaded[lib] = nil
	local loaded = require(lib)
	return loaded
end

require("euclidian.config.snippets")
require("euclidian.config.statusline")
require("euclidian.config.keymaps")

require("euclidian.lib.printmode")
	.set("inspect")
	.override()

hi = require("euclidian.lib.color").scheme.hi
palette = require("euclidian.config.colors")

euclidian = {
	config = setmetatable({}, {
		__index = function(self, key)
			local m = require("euclidian.config." .. key)
			rawset(self, key, m)
			return m
		end
	}),
	lib = setmetatable({}, {
		__index = function(self, key)
			local m = require("euclidian.lib." .. key)
			rawset(self, key, m)
			return m
		end
	}),
}

