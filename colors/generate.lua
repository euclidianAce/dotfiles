local non_newline_patt = "[^\n]+"

local function split_on(text, on)
	local idx = text:find(on, 1, true)
	if not idx then
		return text, nil
	end
	local chopped = text:sub(0, idx - 1)
	local rest = text:sub(idx + 1, -1)
	return chopped, rest
end

local function columns(remaining)
	return function()
		if remaining then
			local result
			result, remaining = split_on(remaining, "\t")
			return result
		end
	end
end

-- uses first column as map key
local function parse_tsv(file_name)
	local contents = assert(io.open(file_name)):read("*a")
	local next_line = contents:gmatch(non_newline_patt)

	local names = {}
	local first_line = next_line()
	for col in columns(first_line) do
		table.insert(names, col)
	end

	local named_rows = {}
	local line_number = 1
	for line in next_line do
		line_number = line_number + 1

		local row = {}

		local next_column = columns(line)
		local row_name = next_column()
		if row_name then
			named_rows[row_name] = row

			local index = 2
			for col in next_column do
				if col == "" then
					col = nil
				end
				if names[index] then
					row[names[index]] = col
					index = index + 1
				else
					io.stderr:write("Extra column(s) in line ", line_number)
					break
				end
			end
		end
	end

	return named_rows
end

local palette = parse_tsv "palette-dark.tsv"
-- for _, entry in pairs(palette) do
	-- for k, v in pairs(entry) do
		-- entry[k] = tonumber(v, 16)
	-- end
-- end

local groups = parse_tsv "group-names.tsv"

local function get_color_by_string(str)
	assert(str)
	local a, b = split_on(str, ".")
	if not a or not b then
		error("No group named " .. str)
		return
	end
	if not palette[b] then
		error("No group named " .. str)
		return
	end
	if not palette[b][a] then
		error("No group named " .. str)
		return
	end
	return palette[b][a]
end

local function generate_vim_colorscheme()
	local lines = {
		"set background=dark",
		"let g:colors_name = 'euclidian'"
	}

	local function ins(...)
		table.insert(lines, table.concat{...})
	end

	local function hi(vim_group_name, group)
		local buf = { "hi ", vim_group_name }

		if group.foreground then
			local actual = get_color_by_string(group.foreground)
			table.insert(buf, " guifg=#")
			table.insert(buf, actual)
		end

		if group.background then
			local actual = get_color_by_string(group.background)
			table.insert(buf, " guibg=#")
			table.insert(buf, actual)
		end

		if group.extra == "emphasis" then
			table.insert(buf, " gui=bold")
		end

		table.insert(lines, "hi clear " .. vim_group_name)
		table.insert(lines, table.concat(buf))
	end

	local vim_group_to_group = {
		["Normal"] = "text",
		["Visual"] = "highlighted-text",
		["Search"] = "searched-highlighted-text",
		["IncSearch"] = "searched-selected-highlighted-text",

		["StatusLine"] = "ui-focused-element-background",
		["StatusLineNC"] = "ui-unfocused-element-background",
		["VertSplit"] = "ui-unfocused-element-background",

		["CursorLine"] = "cursor-line-highlight",
		["CursorLineNr"] = "dark-bg",
		["CursorColumn"] = "cursor-line-highlight",
		["LineNr"] = "faded-text",

		["Comment"] = "syntax-comment",
		["Constant"] = "syntax-literal",
		["Identifier"] = "text",

		["Error"] = "error",
		["ErrorMsg"] = "error",

		["DiagnosticError"] = "error",
		["DiagnosticHint"] = "hint",
		["DiagnosticInfo"] = "text",
		["DiagnosticWarning"] = "warning",

		["Delimiter"] = "syntax-delimiter",

		["Exception"] = "syntax-exceptional",

		["Statement"] = "syntax-keyword",
		["Keyword"] = "syntax-keyword",
		["Operator"] = "syntax-operator",
		["PreProc"] = "syntax-keyword",
		["Type"] = "syntax-type",
		["StorageClass"] = "syntax-attribute",
		["SpecialComment"] = "syntax-todo",
		["Todo"] = "syntax-todo",
		["SpecialChar"] = "syntax-string-escape",
		["Function"] = "syntax-call",
		["Special"] = "bright-text",
		["Tag"] = "bright-text",

		["diffRemoved"] = "git-diff-delete",
		["diffAdded"] = "git-diff-add",
	}

	-- add all the vim-* groups
	for k, v in pairs(groups) do
		if k:sub(1, 4) == "vim-" then
			vim_group_to_group[k:sub(5, -1)] = k
		end
	end

	local p = {}
	for k, v in pairs(vim_group_to_group) do
		table.insert(p, {k,v})
	end
	table.sort(p, function(a, b) return a[1] < b[1] end)

	for _, pair in ipairs(p) do
		if groups[pair[2]] then
			hi(pair[1], groups[pair[2]])
		else
			io.stderr:write("No group named ", pair[2], " for vim group ", pair[1], "\n")
		end
	end

	table.insert(lines, "finish")

	return table.concat(lines, "\n")
end

local function generate_nushell_colorscheme()
	local lines = {}

	local function ins(...)
		table.insert(lines, table.concat{...})
	end

	local function to_var_name(group_name)
		return group_name:gsub("%-", "_") .. "_color"
	end

	local nu_group_to_group = {
		separator = "syntax-delimiter",

		date = "syntax-literal",
		filesize = "syntax-literal",
		row_index = "nu-row_index",

		hints = "hint",
		shape_garbage = "error",

		bool = "syntax-literal",
		int = "syntax-literal",
		duration = "syntax-literal",
		float = "syntax-literal",
		shape_bool = "syntax-literal",
		shape_int = "syntax-literal",
		shape_float = "syntax-literal",
		shape_literal = "syntax-literal",

		shape_pipe = "syntax-operator",
		shape_redirection = "syntax-operator",
		shape_range = "syntax-operator",
		shape_and = "syntax-operator",
		shape_or = "syntax-operator",
		shape_binary = "syntax-operator",
		shape_operator = "syntax-operator",

		shape_signature = "syntax-type",

		string = "bright-text",
		shape_string = "bright-text",
		shape_string_interpolation = "syntax-string-escape",

		shape_filepath = "nu-filepath",
		shape_keyword = "syntax-keyword",

		shape_variable = "syntax-type",
		shape_vardecl = "syntax-type",

		shape_flag = "syntax-literal",

		shape_matching_brackets = "paren-matching",

		header = "nu-header",
		filesize = "nu-filesize",

		search_result = "searched-selected-highlighted-text",

		-- duration: white
		-- range: white
		-- float: white
		-- string: white
		-- nothing: white
		-- binary: white
		-- cell-path: white
		-- row_index: green_bold
		-- record: white
		-- list: white
		-- block: white
		-- shape_and: purple_bold
		-- shape_binary: purple_bold
		-- shape_block: blue_bold
		-- shape_bool: light_cyan
		-- shape_closure: green_bold
		-- shape_custom: green
		-- shape_datetime: cyan_bold
		-- shape_directory: cyan
		-- shape_external: cyan
		-- shape_externalarg: green_bold
		-- shape_flag: blue_bold
		-- shape_float: purple_bold
		-- shape_globpattern: cyan_bold
		-- shape_internalcall: cyan_bold
		-- shape_list: cyan_bold
		-- shape_match_pattern: green
		-- shape_nothing: light_cyan
		-- shape_range: yellow_bold
		-- shape_record: cyan_bold
		-- shape_signature: green_bold
		-- shape_table: blue_bold
	}

	do
		local consts_to_make = {}
		local seen_vars = {}
		for _, v in pairs(nu_group_to_group) do
			if not seen_vars[v] then
				seen_vars[v] = true
				local color = assert(groups[v], "No group named " .. v)
				local var_value = { "{" }
				if color.foreground then
					table.insert(var_value, " fg: " .. ("%q"):format('#' .. get_color_by_string(color.foreground)))
				end
				if color.background then
					table.insert(var_value, " bg: " .. ("%q"):format('#' .. get_color_by_string(color.background)))
				end
				table.insert(var_value, " }")

				table.insert(consts_to_make, { to_var_name(v), table.concat(var_value) })
			end
		end

		table.sort(consts_to_make, function(a, b) return a[1] < b[1] end)

		for _, v in ipairs(consts_to_make) do
			ins("const ", v[1], " = ", v[2])
		end
	end

	local p = {}
	for k, v in pairs(nu_group_to_group) do
		table.insert(p, { k, v })
	end
	table.sort(p, function(a, b) return a[1] < b[1] end)

	ins("export const theme = {")
	for _, pair in ipairs(p) do
		if groups[pair[2]] then
			ins("\t", pair[1], ": $", to_var_name(pair[2]))
		else
			io.stderr:write("No group named ", pair[2], " for nu group ", pair[1], "\n")
		end
	end
	ins("}")

	return table.concat(lines, "\n")
end

local to_generate = ...

if to_generate == "vim" then
	print(generate_vim_colorscheme())
elseif to_generate == "nu" then
	print(generate_nushell_colorscheme())
else
	exit(1)
end
