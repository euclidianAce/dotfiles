
return {
	include_dir = { "teal", "teal/types" },
	preload_modules = { "51compat", "vim" },

	gen_compat = "optional",
	gen_target = "5.1",

	source_dir = "teal",
	build_dir = "lua",

	warning_error = { "unused", "redeclaration" },
}
