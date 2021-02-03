
function confreq(lib)
	return require("euclidian.config." .. lib)
end
function libreq(lib)
	return require("euclidian.lib." .. lib)
end

local util = libreq("util")
local cmdf, autocmd = util.cmdf, util.autocmd

cmdf [[set termguicolors]]
cmdf [[filetype indent on]]
cmdf [[syntax enable]]

require("euclidian.lib.package-manager")
require("euclidian.lib.package-manager.loader").enableSet("World")

local tsLangs = { "teal", "lua", "nix", "javascript", "c" }
require("nvim-treesitter.configs").setup{
	ensure_installed = tsLangs,
	highlight = { enable = tsLangs },
}

autocmd({"BufReadPost"}, {"*.tl", "*.lua"}, [[setlocal syntax= | setlocal foldmethod=expr | setlocal foldexpr=nvim_treesitter#foldexpr() | setlocal sw=3 ts=3]])
autocmd({"BufReadPost"}, {"*.c", "*.h", "*.cpp"}, [[setlocal sw=4 ts=4]])
autocmd({"TextYankPost"}, {"*"}, [[lua vim.highlight.on_yank{ higroup = "STLNormal", timeout = 175, on_macro = true }]])
autocmd({"TermOpen"}, {"*"}, [[setlocal nonumber norelativenumber foldcolumn=0 signcolumn=no]])
autocmd({"Filetype"}, {"lua"}, [[setlocal omnifunc=v:lua.vim.lsp.omnifunc]])
autocmd({"Filetype"}, {"*.c", "*.cpp", "*.h", "*.hpp"}, [[setlocal omnifunc=v:lua.vim.lsp.omnifunc]])

local function set(t, options)
	for opt, val in pairs(options) do
		t[opt] = val
	end
end

set(vim.g, {
	mapleader = " ",
	netrw_liststyle = 3,
	netrw_banner = 0,
})

-- TODO: wat
cmdf [[set undofile]]

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

local lsp = require("lspconfig")
local lspSettings = {
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

confreq("snippets")
confreq("statusline")
confreq("keymaps")

libreq("printmode")
	.set("inspect")
	.override()

hi = libreq("color").scheme.hi
palette = confreq("colors")

euclidian = {
	config = setmetatable({}, {
		__index = function(self, key)
			rawset(self, key, require("euclidian.config." .. key))
			return rawget(self, key)
		end,
	}),
	lib = setmetatable({}, {
		__index = function(self, key)
			rawset(self, key, require("euclidian.lib." .. key))
			return rawget(self, key)
		end,
	})
}

