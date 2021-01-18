
-- Spin up an instance of nvim to get the package.path and stuff
-- This is kinda wonky, but idk how else to do it
do
	local pd = io.popen([[nvim --headless --noplugin -u NORC -n "+lua print(package.path, '\n\n', package.cpath)" -n "+q" 2>&1]], "r")
	local content = pd:read("*a")
	pd:close()
	package.path, package.cpath = content:match("^(%S*)%s+(%S*)$")
	local log = require("tlcli.log")
	local cs = require("tlcli.ui.colorscheme")
	log.verbose("new nvim package.path:\n%s", cs.color("file_name", package.path))
	log.verbose("new nvim package.cpath:\n%s", cs.color("file_name", package.cpath))
end

project "deps"             { "neovim" }
project "preload_modules"  { "vim", "51compat" }
project "include_dir"      { "teal" }

compiler "skip_compat53"

build "options" {
	source_dir = "teal",
	build_dir = "lua",
}

