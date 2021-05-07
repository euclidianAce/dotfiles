
return {
	include_dir = { "teal", "teal/types" },
	global_env_def = "env",

	gen_compat = "off",
	gen_target = "5.1",

	source_dir = "teal",
	build_dir = "lua",

	warning_error = { "unused", "redeclaration" },

	scripts = { ["scripts/apitypes.tl"] = { "build:pre" } },
}
