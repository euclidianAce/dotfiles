
project "deps"             { "neovim" }
project "preload_modules"  { "vim"    }
project "include_dir"      { "teal"   }

compiler "skip_compat53"

build "options" {
	source_dir = "teal",
	build_dir = "lua",
}

