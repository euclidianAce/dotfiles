-- lil baby plugin manager
do
	local plugin_specs = {}
	repeat
		local function add_spec(spec)
			local result = {}
			for _, kind in ipairs { "git", "local_dir" } do
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
			break
		end
		setfenv(f, setmetatable({}, { __index = function(self, k)
			if k == "plugin" then return add_spec end
			return _G[k]
		end}))
		local ok, err = pcall(f)
		if not ok then
			vim.notify("Error loading plugin list: " .. tostring(err), vim.log.levels.ERROR)
			-- don't load anything on error
			plugin_specs = {}
			break
		end
	until true

	local function run(...)
		local command = table.concat({ ... }, " ")
		local result = vim.fn.system(command, " ")
		if vim.v.shell_error ~= 0 then
			vim.notify("Error running command '" .. command .. "':\n" .. result)
			return nil, result
		end
		return result
	end

	local data_path = vim.fn.stdpath "data" .. "/site/pack/plugins/opt"
	if not vim.loop.fs_stat(data_path) then
		run("mkdir", "-p", data_path)
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
				if not vim.loop.fs_stat(location) then
					print("Fetching plugin " .. spec.data)
					if not run("mkdir", "-p", data_path) then break end
					if not run("git", "-C", data_path, "clone", "--depth=1", "--", spec.data, name) then break end
					anything_fetched = true
				end
				vim.cmd("packadd! " .. name)
			elseif spec.kind == "local_dir" then
				vim.opt.runtimepath:append(spec.data)
			end
		until true
	end

	if anything_fetched then
		print("Regenerating helptags")
		vim.cmd "helptags ALL"
	end
end

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
})

vim.cmd "colorscheme euclidian"
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>")
vim.keymap.set("n", "<leader>n", "<cmd>nohlsearch<cr>")
vim.keymap.set("n", "<leader>fz", "<cmd>FZF<cr>")
vim.keymap.set("n", "<leader>rg", "<cmd>Rg<cr>")
