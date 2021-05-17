local windows = vim.fn.has("win32") == 1

-- trick the teal compat code
bit32 = require("bit")

function unload(lib)
	package.loaded[lib] = nil
end

function req(lib)
	unload(lib)
	return require(lib)
end

function confreq(lib, reload)
	if reload then unload(lib) end
	return require("euclidian.config." .. lib)
end
function libreq(lib, reload)
	if reload then unload(lib) end
	return require("euclidian.lib." .. lib)
end

hi = libreq("color").scheme.hi
palette = confreq "colors"

palette.applyHighlights("blue", "purple", "red", "orange")
-- palette.applyHighlights("red", "orange", "blue", "purple")

libreq("printmode")
	.set("inspect")
	.override()

local nvim = libreq("nvim")

nvim.command[[filetype indent on]]
nvim.command[[syntax enable]]

hi.TrailingSpace = hi.Error
nvim.command[[match TrailingSpace /\s\+$/]]

libreq "package-manager" {
	enable = { "World", "Treesitter" },
	maxConcurrentJobs = 6,
}

if not windows then
	-- Treesitter is finicky on windows
	local tsLangs = { "teal", "lua", "javascript", "c", "query", "cpp" }
	require("nvim-treesitter.configs").setup{
		ensure_installed = tsLangs,
		highlight = { enable = tsLangs },
	}
end

local function isExecutable(name)
	return vim.fn.executable(name) == 1
end

if isExecutable("clang-format") then
	nvim.augroup("ClangFormatOnSave", {
		{ "BufWritePre", { "*.hpp", "*.cpp" }, function()
			local win = nvim.Window()
			local cursor = win:getCursor()
			nvim.command [[%%!clang-format]]
			win:setCursor(cursor)
		end }
	})
end

if isExecutable("rustfmt") then
	nvim.augroup("RustFormatOnSave", {
		{ "BufWritePre", "*.rs", function()
			local win = nvim.Window()
			local cursor = win:getCursor()
			nvim.command [[%%!rustfmt]]
			win:setCursor(cursor)
		end }
	})
end

nvim.augroup("Custom", {
	{ "BufReadPost", {"*.tl", "*.lua"}, function()
		local buf = nvim.Buffer()
		local win = nvim.Window()
		win:setOption("foldmethod", "expr")
		win:setOption("foldexpr", "nvim_treesitter#foldexpr()")

		buf:setOption("shiftwidth", 3)
		buf:setOption("tabstop", 3)
	end },

	{ "BufReadPost", {"*.adb", "*.ads"}, function()
		local buf = nvim.Buffer()
		buf:setOption("shiftwidth", 3)
		buf:setOption("tabstop", 3)
		buf:setOption("expandtab", true)

		buf:delKeymap("i", "<space>aj")
		buf:delKeymap("i", "<space>al")
	end },

	{ "BufReadPost", {"*.c", "*.h", "*.cpp", "*.hpp"}, function()
		local buf = nvim.Buffer()
		buf:setOption("shiftwidth", 4)
		buf:setOption("tabstop", 4)
		buf:setOption("commentstring", "// %s")
	end },

	{ "TextYankPost", "*", function()
		vim.highlight.on_yank{ higroup = "STLNormal", timeout = 175, on_macro = true }
	end },

	{ "TermOpen", "*", function()
		local win = nvim.Window()
		win:setOption("number", false)
		win:setOption("relativenumber", false)
		win:setOption("signcolumn", "no")
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
	guicursor = "a:block",
	-- guicursor = "n:hor10",
	-- guicursor = "i:ver20",

	mouse = "nv",
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
	listchars = "tab:   ,space:·,precedes:<,extends:>,nbsp:+",
	fillchars = "fold: ,vert: ",
	inccommand = "nosplit",
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
if not lspconfig.teal and isExecutable("teal-language-server") then
	configs.teal = {
		default_config = {
			cmd = {
				"teal-language-server",
				-- "logging=on",
			},
			filetypes = { "teal", "lua" },
			root_dir = lspconfig.util.root_pattern("tlconfig.lua", ".git"),
			settings = {},
		},
	}
	lspconfig.teal.setup{}
end
lspconfig.clangd.setup{}

confreq("statusline")
confreq("keymaps")

local function requirer(str)
	return setmetatable({}, {
		__index = function(self, key)
			rawset(self, key, require(str .. "." .. key))
			return rawget(self, key)
		end,
	})
end

euclidian = {
	lib = requirer("euclidian.lib"),
	config = requirer("euclidian.config"),
}
e = euclidian
e.l = euclidian.lib
e.c = euclidian.config

confreq("luasearch")

if vim.fn.exists(":GuiRenderLigatures") == 2 then
	nvim.command[[GuiRenderLigatures 1]]
end
if vim.fn.exists(":GuiFont") == 2 then
	-- apparently just "JuliaMono" doesn't have ligatures?
	nvim.command[[GuiFont! JuliaMono Medium:h10]]
end

setmetatable(_G, {
	__index = function(_, key)
		for _, r in ipairs{libreq, confreq} do
			local ok, res = pcall(r, key)
			if ok then
				return res
			end
		end
		local ok, res = pcall(require, key)
		if ok then
			return res
		end
		return nil
	end
})
