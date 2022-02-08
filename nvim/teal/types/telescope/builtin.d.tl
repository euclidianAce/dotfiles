
local record builtin
	find_files: function
	file_browser: function
	live_grep: function

	record GrepStringOpts
		search: string
		search_dirs: {string}
		use_regex: boolean
	end
	grep_string: function(GrepStringOpts)
end

return builtin
