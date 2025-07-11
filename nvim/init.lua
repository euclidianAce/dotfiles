-- lil baby plugin manager
local function do_plugins(force_update)
	local plugin_specs = {}
	local function add_spec(spec)
		local result = {}
		for _, kind in ipairs { "git", "local_dir", "tar" } do
			if spec[kind] then
				result.kind = kind
				result.data = spec[kind]
				break
			end
		end
		if not result.kind then
			error("Unknown plugin kind '" .. tostring((next(spec))) .. "'", 2)
		end
		table.insert(plugin_specs, result)
	end
	local f, err = loadfile(os.getenv "HOME" .. "/.config/nvim/plugins.lua")
	if not f then
		vim.notify("Could not load plugin list: " .. tostring(err), vim.log.levels.WARN)
		return
	end
	setfenv(f, setmetatable({}, { __index = function(self, k)
		if k == "plugin" then return add_spec end
		return _G[k]
	end }))
	local ok, err = pcall(f)
	if not ok then
		vim.notify("Error loading plugin list: " .. tostring(err), vim.log.levels.ERROR)
		-- don't load anything on error
		plugin_specs = {}
		return
	end

	local function run(...)
		local result = vim.fn.system({ ... }, "")
		if vim.v.shell_error ~= 0 then
			vim.notify("Error running command '" .. table.concat({ ... }, " ") .. "':\n" .. result)
			return nil, result
		end
		return result
	end

	local data_path = vim.fn.stdpath "data" .. "/site/pack/plugins/opt"
	if force_update then
		if not run("rm", "-r", data_path) then return end
	end
	if force_update or not vim.loop.fs_stat(data_path) then
		if not run("mkdir", "-p", data_path) then return end
	end

	local anything_fetched = false
	for _, spec in ipairs(plugin_specs) do
		repeat
			if spec.kind == "git" then
				-- transform to local path
				local s, e = spec.data:find("/([^/]-)$")
				assert(s)
				local name = spec.data:sub(s + 1, e)
				if name:sub(-4, -1) == ".git" then
					name = name:sub(1, -5)
				end
				assert(#name > 0)
				local location = data_path .. "/" .. name
				if force_update or not vim.loop.fs_stat(location) then
					vim.notify("Fetching (git) plugin " .. spec.data)
					if not run("mkdir", "-p", data_path) then break end
					if not run("git", "-C", data_path, "clone", "--depth=1", "--", spec.data, name) then break end
					anything_fetched = true
				end
				vim.cmd("packadd! " .. name)
			elseif spec.kind == "local_dir" then
				vim.opt.runtimepath:append(spec.data)
			elseif spec.kind == "tar" then
				if not spec.data.name then
					vim.notify("Tar plugin without a name '" .. spec.data.url .. "'")
					break
				end
				local location = data_path .. "/" .. spec.data.name
				if force_update or not vim.loop.fs_stat(location) then
					if not run("mkdir", "-p", location) then break end
					vim.notify("Fetching (tar) plugin " .. spec.data.name)
					if not run("wget", "--output-document=" .. location .. ".tarball", spec.data.url) then break end
					local is_gzip = spec.data.url:match("%.gz$")
					vim.notify("Extracting (tar) plugin " .. spec.data.name)
					if not run(
						"tar",
						"--directory=" .. location,
						"--strip-components=1",
						"-x" .. (is_gzip and "z" or "") .. "f",
						location .. ".tarball"
					) then break end
					run("rm", location .. ".tarball")
				end
				vim.cmd("packadd! " .. spec.data.name)
			end
		until true
	end

	if anything_fetched then
		vim.notify("Regenerating helptags")
		vim.cmd "helptags ALL"
	end
end

do_plugins()

vim.api.nvim_create_user_command("UpdatePlugins", function()
	vim.notify("Updating/redownloading plugins...")
	do_plugins(true)
end, {
	desc = "Redownload all plugins"
})

-- add local-plugins dir to rtp
local dotdir = os.getenv "DOTFILE_DIR"
if dotdir then
	local pkgs = dotdir .. "/nvim/local-plugins/"
	vim.opt.packpath:append(pkgs)
	pcall(vim.cmd, "source " .. pkgs .. "init.vim")
end

-- configuration
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
	termguicolors = true,
	guicursor = "a:block",
	-- guicursor = "i-c-ci-ve:ver5,r-cr-o:hor25,n-v-sm:block,a:Cursor",
	-- guicursor = "i-c-ci-ve-r-cr-o:block,n-v-sm:hor15,a:Cursor",
	-- guicursor = "i-c-ci:ver5,ve-r-cr-o:block,n-v-sm:hor15,a:Cursor",
	number = true,
	relativenumber = true,
	numberwidth = 4,
	undofile = true,
	mouse = "nv",
	breakindent = true,
	lazyredraw = true,
	splitbelow = true,
	splitright = true,
	-- showmode = false,
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
	scrolloff = 2,
	virtualedit = { "block", "onemore" },
	cursorline = true,
	cursorlineopt = { "number", "line" },
	equalalways = false,
	list = true,
	formatoptions = "croqlj",

	signcolumn = "yes:1",

	statusline = " %4n %t %{FugitiveStatusline()} %h%q%m%w %= Line %l of %L ",

	cinoptions =
		":0" -- case labels indented same as switch
		.. ",=s"
		.. ",l1" -- indent case statements normally
		.. ",g0" -- c++ public/private
		.. ",N0" -- namespace indent
		.. ",Ws"
	,
})

vim.api.nvim_create_autocmd("TextYankPost", {
	pattern = "*",
	callback = function()
		vim.highlight.on_yank { higroup = "EuclidianYankHighlight", timeout = 400 }
	end,
	desc = "Highlight yanked text",
})

do
	local mode_regex = vim.regex "(c|r.?|!t)"
	vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
		pattern = "*",
		callback = function(event)
			local mode = vim.api.nvim_get_mode().mode
			if not mode_regex:match_str(mode) and vim.fn.getcmdwintype() == "" then
				vim.cmd "checktime"
			end
		end,
		desc = "Reloads files when they are changed on disk",
	})
end

vim.cmd "colorscheme euclidian"
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Make <Esc> be normal in terminal mode" })
vim.keymap.set({"v", "n"}, "K", "<nop>", { desc = "Get rid of stupidly laggy man page mapping" })
vim.keymap.set("n", "<leader>n", "<cmd>nohlsearch<cr>", { desc = "Clear search highlights" })
vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Set location list from diagnostics" })

vim.api.nvim_set_hl(0, "LspInlayHint", { link = "EuclidianDelimiter" })

vim.keymap.set("n", "<leader>fz", "<cmd>FZF<cr>", { desc = "Open fzf" })
vim.keymap.set("n", "<leader>rg", "<cmd>Rg<cr>", { desc = "Open ripgrep" })
if os.getenv "TMUX" then
	vim.g.fzf_layout = { tmux = '90%,70%' }
end

vim.api.nvim_create_user_command("Term", function(opts)
	for _, id in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_name(id):sub(1, 7) == "term://" then
			vim.cmd("sp | buffer " .. id)
			vim.notify("Found existing terminal (buffer " .. id .. ")")
			return
		end
	end
	vim.cmd("sp +term")
	vim.notify("Created new terminal")
end, {
	desc = "Find or create a terminal",
})

local function optional_require(name)
	local ok, ret = pcall(require, name)
	if not ok then return nil end
	return ret
end

local lspconfig = optional_require "lspconfig"

if lspconfig then
	vim.g.zig_fmt_autosave = 0

	-- semantic tokens are buggy
	lspconfig.util.default_config.on_init = function(client)
		client.server_capabilities["semanticTokensProvider"] = nil
	end

	local function is_executable(str)
		return vim.fn.executable(str) ~= 0
	end

	if is_executable "zls" then lspconfig.zls.setup {} end
	if is_executable "rust-analyzer" then lspconfig.rust_analyzer.setup {} end
	if is_executable "harper-ls" then lspconfig.harper_ls.setup {} end

	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(ev)
			local function o(desc) return { buffer = ev.buf, desc = desc } end
			vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format { async = true } end, o "LSP: Run formatter")
			vim.keymap.set({ "n", "v" }, "<leader>a", vim.lsp.buf.code_action, o "LSP: Code action")
			vim.keymap.set("n", "K", vim.lsp.buf.hover, o "LSP: Hover")
			vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, o "LSP: Signature help")
		end
	})

	vim.diagnostic.config {
		virtual_text = false,
	}

	if vim.lsp.inlay_hint then
		vim.lsp.inlay_hint.enable()
	end
end

local err_jump = optional_require "error-jump"
if err_jump then
	vim.api.nvim_create_autocmd("BufFilePost", {
		callback = function(ev)
			local name = vim.api.nvim_buf_get_name(ev.buf)
			if name:sub(1, 7) ~= "term://" then
				return
			end

			vim.keymap.set("n", "<cr>", err_jump.on_key_wrapper(err_jump.default_handler), {
				buffer = ev.buf,
				desc = "Goto compile error location under the cursor",
			})
			--vim.keymap.set("v", "<cr>", err_jump.on_key_wrapper(err_jump.default_handler), {
			--	buffer = ev.buf,
			--	desc = "Goto visually selected compile error location",
			--})
		end
	})
end

local whitespace_highlighter = optional_require "whitespace-highlighter"
if whitespace_highlighter then
	whitespace_highlighter.enable()

	vim.api.nvim_create_user_command("HighlightSpaces", function(args)
		(args.bang and whitespace_highlighter.disable or whitespace_highlighter.enable)()
	end, { bang = true })
end
