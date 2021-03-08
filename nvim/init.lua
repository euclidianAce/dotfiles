
-- trick the teal compat code
bit32 = require("bit")

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

local tsLangs = { "teal", "lua", "nix", "javascript", "c", "query", "cpp" }
require("nvim-treesitter.configs").setup{
	ensure_installed = tsLangs,
	highlight = { enable = tsLangs },
}

nvim.augroup("Custom", {
	{ "BufReadPost", {"*.tl", "*.lua"}, function()
		local buf = nvim.Buffer()
		local win = nvim.Window()
		win:setOption("foldmethod", "expr")
		win:setOption("foldexpr", "nvim_treesitter#foldexpr()")

		buf:setOption("syntax", "")
		buf:setOption("shiftwidth", 3)
		buf:setOption("tabstop", 3)
	end },


	{ "BufReadPost", {"*.c", "*.h", "*.cpp", "*.hpp"}, function()
		local buf = nvim.Buffer()
		buf:setOption("shiftwidth", 4)
		buf:setOption("tabstop", 4)
	end },

	{ "TextYankPost", "*", function()
		vim.highlight.on_yank{ higroup = "STLNormal", timeout = 175, on_macro = true }
	end },

	{ "TermOpen", "*", function()
		local win = nvim.Window()
		win:setOption("number", false)
		win:setOption("relativenumber", false)
		win:setOption("foldcolumn", "0")
		win:setOption("signcolumn", "no")
		win:setOption("cursorline", false)
	end },
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
	-- guicursor = "",
	-- guicursor = "n:hor10",
	-- guicursor = "n:hor10,i:ver10",

	mouse = "a",
	termguicolors = true,
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
	virtualedit = "block",
	foldmethod = "marker",
})

set(vim.bo, {
	formatoptions = "lroj",
})

set(vim.wo, {
	list = true,
	signcolumn = "yes:1",
	numberwidth = 4,
	number = true,
	relativenumber = true,
	-- cursorline = true,
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
lspconfig.clangd.setup{}

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

