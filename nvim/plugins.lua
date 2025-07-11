-- plugin { git = "https://github.com/teal-language/vim-teal" }
plugin { git = "https://tpope.io/vim/fugitive.git" }
plugin { tar = { url = "https://github.com/neovim/nvim-lspconfig/archive/refs/tags/v1.6.0.tar.gz", name = "lspconfig" } }
plugin { git = "https://github.com/kaarmu/typst.vim.git" }
plugin { git = "https://github.com/NoahTheDuke/vim-just.git" }

local fzf_share_dir = vim.fn.system("fzf-share"):sub(1, -2)
if vim.v.shell_error == 0 then
	plugin { local_dir = fzf_share_dir .. "/../nvim/site" }
	plugin { git = "https://github.com/junegunn/fzf.vim" }
end
