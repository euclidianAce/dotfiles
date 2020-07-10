return {
	include_dir = {
		os.getenv("HOME") .. "/dev/teal-types/types/nvim_api/",
	},
	skip_compat53 = true,
	preload_modules = {"vim"},
	source_dir = "teal",
	build_dir = "lua",
	include = {"**/*"},
}
