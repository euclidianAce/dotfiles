__euclidian = {}

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

confload = vim.schedule_wrap(function(lib, reload)
	if reload then unload("euclidian.config." .. lib) end
	require("euclidian.config." .. lib)
end)
function libreq(lib, reload)
	if reload then unload("euclidian.lib." .. lib) end
	return require("euclidian.lib." .. lib)
end
function plugreq(lib, reload)
	if reload then unload("euclidian.plug." .. lib) end
	return require("euclidian.plug." .. lib)
end

hi = libreq("color").scheme.hi

local nvim = libreq("nvim")
nvim.command[[colorscheme euclidian]]

nvim.command[[filetype indent on]]
nvim.command[[syntax enable]]

local function set(t, options)
	for opt, val in pairs(options) do
		t[opt] = val
	end
end

set(vim.g, {
	mapleader = " ",
	loaded_gzip = 1,
	loaded_tar = 1,
	loaded_tarPlugin = 1,
	loaded_zipPlugin = 1,
	loaded_2html_plugin = 1,
	loaded_netrw = 1,
	loaded_netrwPlugin = 1,
	loaded_spec = 1,
})

set(vim.opt, {
	guicursor = "i-c:ver10,o-r-v:hor10,a:blinkoff250-blinkon250-Cursor",
	-- guicursor = "a:block",
	-- guicursor = "n:hor15",
	-- guicursor = "n:hor15,i:ver30",

	undofile = true,
	mouse = "nv",
	termguicolors = true,
	belloff = "all",
	swapfile = false,
	updatetime = 1250,
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
	listchars = { tab = "   ", space = "·", precedes = "<", extends = ">", nbsp = "+" },
	fillchars = { fold = " ", vert = " " },
	inccommand = "nosplit",
	laststatus = 2,
	scrolloff = 2,
	virtualedit = "block",
	foldmethod = "marker",

	formatoptions = "lroj",

	list = true,
	signcolumn = "yes:1",
	numberwidth = 4,
	number = true,
	relativenumber = true,
})

plugreq "package-manager"
plugreq "floatterm" {
	toggle = "",
	shell = windows and "nu" or "bash",
	termopenOpts = { env = { FLOATTERM = 1 } },

	row = 1,
	centered = { horizontal = true },
}
plugreq "scripter" {
	open = "<leader>lua",
}
plugreq "spacehighlighter"
	.enable()
libreq "printmode"
	.set "inspect"
	.override()
plugreq "manfolder"


if not windows then
	-- Treesitter is finicky on windows
	local tsLangs = { "teal", "lua", "javascript", "c", "query", "nix" }
	require("nvim-treesitter.configs").setup{
		ensure_installed = tsLangs,
		highlight = { enable = tsLangs },
	}
end

local function isExecutable(name) return vim.fn.executable(name) == 1 end

local function runFormatter(...)
	local buf = nvim.Buffer()
	local win = nvim.Window()
	local cursor = win:getCursor()
	nvim.command(...)
	cursor[1] = math.min(#buf:getLines(0, -1, false), cursor[1])
	win:setCursor(cursor)
end

if isExecutable("clang-format") then
	nvim.augroup("ClangFormatOnSave", {
		{ "BufWritePre", { "*.c", "*.h", "*.hpp", "*.cpp" }, function()
			runFormatter([[%%!clang-format -style=file --assume-filename=%s]], nvim.Buffer():getName() or "")
		end, { canError = true } }
	})
end

if isExecutable("rustfmt") then
	nvim.augroup("RustFormatOnSave", {
		{ "BufWritePre", "*.rs", function() runFormatter("rustfmt") end }
	})
end

nvim.augroup("Custom", {
	{ "FileType", {"teal", "lua"}, function()
		local buf = nvim.Buffer()
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

local lspconfig = require("lspconfig")
local configs = require("lspconfig/configs") -- THIS HAS TO BE A SLASH
if not lspconfig.teal and isExecutable("teal-language-server") then
	configs.teal = {
		default_config = {
			cmd = {
				"teal-language-server",
				-- "logging=on",
			},
			filetypes = {
				"teal",
				-- "lua"
			},
			root_dir = lspconfig.util.root_pattern("tlconfig.lua", ".git"),
			settings = {},
		},
	}
	lspconfig.teal.setup{}
end
-- if isExecutable("clangd") then
	-- lspconfig.clangd.setup{}
-- end

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
	vim.lsp.diagnostic.on_publish_diagnostics, { virtual_text = false })

confload("statusline")
confload("keymaps")

local function requirer(str)
	return setmetatable({}, {
		__index = function(self, key)
			rawset(self, key, require(str .. "." .. key))
			return rawget(self, key)
		end,
	})
end

if vim.fn.exists(":GuiRenderLigatures") == 2 then
	nvim.command[[GuiRenderLigatures 1]]
end
if vim.fn.exists(":GuiFont") == 2 then
	-- apparently just "JuliaMono" doesn't have ligatures?
	nvim.command[[GuiFont! JuliaMono Medium:h10]]
end

nvim.newCommand{ name = "Lua", complete = "lua", nargs = "*", body = "lua print(<args>)" }

setmetatable(_G, {
	__index = function(_, key)
		for _, r in ipairs{libreq, plugreq} do
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
