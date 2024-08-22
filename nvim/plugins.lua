plugin { git = "https://github.com/teal-language/vim-teal" }
plugin { git = "https://tpope.io/vim/fugitive.git" }
plugin { tar = { url = "https://github.com/neovim/nvim-lspconfig/archive/refs/tags/v0.1.8.tar.gz", name = "lspconfig" } }

local fzf_share_dir = vim.fn.system("fzf-share"):sub(1, -2)
if vim.v.shell_error == 0 then
	plugin { local_dir = fzf_share_dir .. "/../nvim/site" }
	plugin { git = "https://github.com/junegunn/fzf.vim" }
end
