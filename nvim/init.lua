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
	if reload then unload("euclidian.plug." .. lib .. ".api") end
	return require("euclidian.plug." .. lib .. ".api")
end
function plugload(lib, reload)
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
	loaded_spec = 1,

	netrw_banner = 0,
})

set(vim.opt, {
	-- guicursor = "i-c:ver15,o-r-v:hor30,a:blinkwait700-blinkon1200-blinkoff400-Cursor",
	guicursor = "a:block",
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
	fillchars = {
		fold = " ",
		horiz = " ",
		horizup = " ",
		horizdown = " ",
		vert = " ",
		vertleft = " ",
		vertright = " ",
		verthoriz = " ",
	},
	inccommand = "nosplit",
	laststatus = 2,
	cmdheight = 0,
	scrolloff = 2,
	virtualedit = "block",
	foldmethod = "marker",
	foldenable = true,
	cursorline = true,
	cursorlineopt = "number",
	equalalways = false,

	formatoptions = "lrojq",

	list = true,

	signcolumn = "yes:1",
	numberwidth = 4,
	number = true,
	relativenumber = true,
})

plugload "package-manager"
-- TODO: package-manager needs a way to do this
require "treesitter-context".setup {}

local shell = windows and "nu" or "bash"
plugload "floatterm" {
	{
		{ row = 1, wid = 0.9, hei = 0.8, centered = { horizontal = true }, notMinimal = true },
		shell,
		{},
		{ toggle = { {"n", "t"}, ""} }
	},
	{
		{ row = 3, wid = 0.9, hei = 0.8, centered = { horizontal = true }, notMinimal = true },
		shell,
		{},
		{ toggle = { {"n", "t"}, ""} }
	},
}
plugload "spacehighlighter" {
	highlight = "TrailingWhitespace",
}
plugload "printmode" {
	mode = "inspect",
}
plugload "manfolder"
plugload "locationjump" {
	vmap = "J",
	openWith = function(file, line)
		local ft = plugreq("floatterm")
		local term = ft.fromWindow()
		if term then term:hide() end
		plugreq("locationjump").jump(file, line)
	end,
}
plugload "palette" { theme = "default" }
plugload "ui"
plugload "align"

if not windows then
	-- Treesitter is finicky on windows
	local tsLangs = { "teal", "lua", "javascript", "c", "query", "nix" }
	require("nvim-treesitter.configs").setup{
		ensure_installed = tsLangs,
		highlight = { enable = tsLangs },
	}
end

local function isExecutable(name) return vim.fn.executable(name) == 1 end

do
	local group = nvim.createAugroup("Custom")
	group:add("FileType", {
		pattern = { "teal", "lua" },
		callback = function()
			local buf = nvim.Buffer()
			buf:setOption("shiftwidth", 3)
			buf:setOption("tabstop", 3)
		end,
		desc = "Set tabstop and shiftwidth",
	})
	group:add("BufReadPost", {
		pattern = { "*.adb", "*.ads" },
		callback = function()
			local buf = nvim.Buffer()
			buf:setOption("shiftwidth", 3)
			buf:setOption("tabstop", 3)
			buf:setOption("expandtab", true)

			buf:delKeymap("i", "<space>aj")
			buf:delKeymap("i", "<space>al")
		end,
		desc = "Remove stupid Ada insert mode bindings",
	})
	group:add("BufReadPost", {
		pattern = { "*.c", "*.h", "*.cpp", "*.hpp" },
		callback = function()
			local buf = nvim.Buffer()
			buf:setOption("commentstring", "// %s")
		end,
		desc = "Set proper commentstring",
	})
	group:add("TextYankPost", {
		callback = function()
			vim.highlight.on_yank{ higroup = "STLNormal", timeout = 175, on_macro = true }
		end,
		desc = "Highlight yanks",
	})
	group:add("TermOpen", {
		callback = function()
			local win = nvim.Window()
			win:setOption("number", false)
			win:setOption("relativenumber", false)
			win:setOption("signcolumn", "no")
		end,
		desc = "Set window options for terminal windows (remove line numbers and sign column)",
	})
end

local lspconfig = require("lspconfig")
local configs = require("lspconfig.configs")
if not configs.teal and isExecutable("teal-language-server") then
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

vim.diagnostic.config{
	virtual_text = {
		prefix = "",
	}
}

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
	-- nvim.command[[GuiFont! JuliaMono Medium:h10]]
	nvim.command[[GuiFont! Ubuntu Mono:h12]]
end

nvim.api.createUserCommand("Lua", ":lua print(<args>)<cr>", { complete = "lua", nargs = "*" })
nvim.api.createUserCommand(
	"Make",
	function()
		local buf = nvim.Buffer()
		nvim.command("make")
		vim.diagnostic.set(
			nvim.api.createNamespace("euclidian.Make"),
			buf.id,
			vim.diagnostic.fromqflist(vim.fn.getqflist())
		)
	end,
	{}
)

nvim.api.createUserCommand(
	"ToHex",
	function(args)
		print(("0x%x"):format(tonumber(args.args)))
	end,
	{ nargs = 1 }
)

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
