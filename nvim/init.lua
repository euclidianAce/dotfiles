
function confreq(lib)
	return require("euclidian.config." .. lib)
end
function libreq(lib)
	return require("euclidian.lib." .. lib)
end

libreq "printmode"
	.set "inspect"
	.override()

local nvim = libreq "nvim"

nvim.command[[filetype indent on]]
nvim.command[[syntax enable]]

libreq "package-manager" {
	enable = {
		"World",
		"TSPlayground",
	}
}

local tsLangs = { "teal", "lua", "nix", "javascript", "c", "query" }
require("nvim-treesitter.configs").setup{
	ensure_installed = tsLangs,
	highlight = { enable = tsLangs },
}

nvim.augroup("Custom", {
	{ "BufReadPost", {"*.tl", "*.lua"},
		[[setlocal syntax= | setlocal foldmethod=expr | setlocal foldexpr=nvim_treesitter#foldexpr() | setlocal sw=3 ts=3]] },

	{ "BufReadPost", {"*.c", "*.h", "*.cpp"}, [[setlocal sw=4 ts=4]] },

	{ "TextYankPost", "*",
		[[lua vim.highlight.on_yank{ higroup = "STLNormal", timeout = 175, on_macro = true }]] },

	{ "TermOpen", "*", [[setlocal nonumber norelativenumber foldcolumn=0 signcolumn=no]] },

	{ "Filetype", "lua", [[setlocal omnifunc=v:lua.vim.lsp.omnifunc]] },

	{ "Filetype", {"*.tl", "*.c", "*.cpp", "*.h", "*.hpp"}, [[setlocal omnifunc=v:lua.vim.lsp.omnifunc]] },
})

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
nvim.command [[set undofile]]

set(vim.o, {
	termguicolors = true,
	mouse = "a",
	-- guicursor = "",
	guicursor = "n:hor10,i:ver10",
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
	listchars = "tab:   ,trail:-,space:·,precedes:<,extends:>,nbsp:+",
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
	numberwidth = 4,
	number = true,
	relativenumber = true,
})

local lspconfig = require("lspconfig")
local configs = require("lspconfig/configs") -- THIS HAS TO BE A SLASH
if not lspconfig.teal then
	configs.teal = {
		default_config = {
			cmd = {
				"teal-language-server",
				"logging=on",
			},
			filetypes = { "teal" };
			root_dir = lspconfig.util.root_pattern("tlconfig.lua", ".git"),
			settings = {};
		},
	}
end
lspconfig.teal.setup{}

function req(lib)
	package.loaded[lib] = nil
	local loaded = require(lib)
	return loaded
end

confreq "statusline"
confreq "keymaps"

local function requirer(str)
	return setmetatable({}, {
		__index = function(self, key)
			rawset(self, key, require(str .. "." .. key))
			return rawget(self, key)
		end,
	})
end

hi = libreq "color" .scheme.hi
palette = confreq "colors"

euclidian = {
	config = requirer("euclidian.config"),
	lib = requirer("euclidian.lib")
}

