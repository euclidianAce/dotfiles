
local cmdf = require("euclidian.lib.util").cmdf

local Plugin = {}


local req = require

require("euclidian.config")


req("nvim-treesitter.configs").setup({
   ensure_installed = "maintained",
   highlight = { enable = true },
})

req("colorizer").setup()

cmdf([[autocmd BufRead *.tl setlocal foldmethod=expr | setlocal foldexpr=nvim_treesitter#foldexpr()]])
cmdf([[autocmd TextYankPost * lua vim.highlight.on_yank{ higroup = "STLNormal", timeout = 175, on_macro = true }]])

local o = vim.o

local opts = {
   termguicolors = true,
   belloff = "all",
   undodir = os.getenv("HOME") .. "/.vim/undo",
   undofile = true,
   noswapfile = true,
   switchbuf = "useopen",
   number = true,
   relativenumber = true,
   numberwidth = 4,
   wildmenu = true,
   showcmd = true,
   breakindent = true,
   lazyredraw = true,
   splitbelow = true,
   splitright = true,
   incsearch = true,
   noshowmode = true,
   modeline = true,
   linebreak = true,
   ignorecase = true,
   smartcase = true,
   gdefault = true,
   listchars = "tab:  │,eol:↵,trail:✗,space:·,precedes:<,extends:>,nbsp:+",
   list = true,
   fillchars = "fold: ",
   inccommand = "split",
   laststatus = 2,
   scrolloff = 2,
   formatoptions = "lcroj",
   virtualedit = "block",
   signcolumn = "yes:1",
   foldcolumn = 3,
   foldmethod = "marker",
}

for opt, val in pairs(opts) do
   vim.o[opt] = val
end
