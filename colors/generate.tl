local function split_on(text: string, on: string): string, string
	local idx = text:find(on, 1, true)
	if not idx then
		return text, nil
	end
	local chopped <const> = text:sub(1, idx - 1)
	local rest <const> = text:sub(idx + 1, -1)
	return chopped, rest
end

local function columns(remaining: string): function(): string
	return function(): string
		if remaining then
			local result: string
			result, remaining = split_on(remaining, "\t")
			return result
		end
	end
end

-- uses first column as map key
local function parse_tsv(file_name: string): {string:{string:string}}
	local contents <const> = assert(io.open(file_name)):read("*a")
	local next_line <const> = contents:gmatch("[^\n]+")

	local names <const> = {}
	local first_line <const> = next_line()
	for col in columns(first_line) do
		table.insert(names, col)
	end

	local named_rows <const> = {}
	local line_number = 1
	for line in next_line do
		line_number = line_number + 1

		local row <const> = {}

		local next_column <const> = columns(line)
		local row_name <const> = next_column()
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

local function ordered_keys<T>(t: {string:T}): {string}
	local keys <const> = {}
	for k in pairs(t) do
		table.insert(keys, k)
	end
	table.sort(keys)
	return keys
end

local palette <const> = parse_tsv "palette-dark.tsv"
local palette_names <const> = ordered_keys(palette)
-- for _, entry in pairs(palette) do
	-- for k, v in pairs(entry) do
		-- entry[k] = tonumber(v, 16)
	-- end
-- end

local function generate_ansi(): string
	local keys <const> = {}
	for k in pairs(palette) do
		table.insert(keys, k)
	end
	table.sort(keys)

	local lines <const> = {}

	for _, k in ipairs(keys) do
		local v <const> = palette[k]
		local buf <const> = {}
		for _, str_component in ipairs{ v.dark, v.normal, v.bright } do
			local component = tonumber(str_component, 16)
			table.insert(buf, ("\x1b[48;2;%d;%d;%dm      \x1b[0m"):format(
				component >> 16,
				(component >> 8) & 0xff,
				component & 0xff
			))
		end
		table.insert(lines, k .. "\t" .. table.concat(buf, " "))
	end

	return table.concat(lines, "\n")
end

local groups: {string:{string:string}}
local group_names: {string}

local function get_color_by_string(str: string): string
	assert(str)
	local a <const>, b <const> = split_on(str, ".")
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

local function add_all_groups_with_prefix(prefix: string, to_add_to: {string:string})
	for k in pairs(groups) do
		if k:sub(1, #prefix) == prefix then
			local name = k:sub(#prefix + 1, -1)
			if to_add_to[name] then
				io.stderr:write("Warning: ", name, " was overridden by ", k, " in group-names.tsv\n")
			end
			to_add_to[name] = k
		end
	end
end

local function generate_vim_colorscheme(): string
	local lines <const> = {
		"set background=dark",
		"let g:colors_name = 'euclidian'"
	}

	local function ins(...: string)
		table.insert(lines, table.concat{...})
	end

	local quirky_groups <const>: {string:boolean} = {
		["Normal"] = true,
		["EuclidianYankHighlight"] = true,
		["EuclidianTrailingWhitespace"] = true,
	}

	local function hi(vim_group_name: string, group: {string:string})
		local theme_group_name <const> = quirky_groups[vim_group_name]
			and vim_group_name
			or "Euclidian" .. vim_group_name:sub(1, 1):upper() .. vim_group_name:sub(2, -1):gsub("%-([a-z])", string.upper)

		local buf <const> = { "hi ", theme_group_name }

		if group.foreground then
			local actual <const> = get_color_by_string(group.foreground)
			table.insert(buf, " guifg=#")
			table.insert(buf, actual)
		end

		if group.background then
			local actual <const> = get_color_by_string(group.background)
			table.insert(buf, " guibg=#")
			table.insert(buf, actual)
		end

		if group.extra == "emphasis" then
			table.insert(buf, " gui=bold")
		end

		table.insert(lines, table.concat(buf))
		if not quirky_groups[vim_group_name] then
			ins("hi clear ", vim_group_name)
			ins("hi! link ", vim_group_name, " ", theme_group_name)
		end
	end

	local vim_group_to_group <const>: {string:string} = {
		["Normal"] = "normal-fg-bg",
		["Visual"] = "highlighted-text",
		["Search"] = "searched-highlighted-text",
		["IncSearch"] = "searched-selected-highlighted-text",

		["StatusLine"] = "ui-focused-element-background",
		["StatusLineNC"] = "ui-unfocused-element-background",
		["VertSplit"] = "ui-unfocused-element-background",
		["WinSeparator"] = "ui-unfocused-element-background",

		["CursorLine"] = "cursor-line-highlight",
		["CursorLineNr"] = "dark-bg",
		["CursorColumn"] = "cursor-line-highlight",
		["LineNr"] = "faded-text",

		["Comment"] = "syntax-comment",
		["Constant"] = "syntax-literal",
		["String"] = "syntax-literal",
		["Identifier"] = "text",
		["@variable"] = "text",

		["Error"] = "error",
		["ErrorMsg"] = "error",

		["DiagnosticError"] = "error",
		["DiagnosticHint"] = "hint",
		["DiagnosticInfo"] = "text",
		["DiagnosticWarning"] = "warning",

		["MatchParen"] = "paren-matching",

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

		-- custom
		["EuclidianYankHighlight"] = "bright-highlighted-text",
		["EuclidianTrailingWhitespace"] = "trailing-whitespace",
	}

	add_all_groups_with_prefix("@vim-", vim_group_to_group)

	local p <const> = {}
	for k, v in pairs(vim_group_to_group) do
		table.insert(p, {k,v})
	end
	table.sort(p, function(a: {string}, b: {string}): boolean return a[1] < b[1] end)

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

local function generate_nushell_colorscheme(): string
	local lines <const> = {}

	local function ins(...: string)
		table.insert(lines, table.concat{...})
	end

	local function to_var_name(group_name: string): string
		return group_name:gsub("%-", "_") .. "_color"
	end

	local nu_group_to_group <const>: {string:string} = {
		separator = "syntax-delimiter",

		date = "syntax-literal",

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

		shape_keyword = "syntax-keyword",

		shape_variable = "syntax-type",
		shape_vardecl = "syntax-type",

		shape_flag = "syntax-literal",

		shape_matching_brackets = "paren-matching",

		search_result = "searched-selected-highlighted-text",

		shape_external = "bright-text",
		shape_externalarg = "text",

		-- duration: white
		-- range: white
		-- float: white
		-- string: white
		-- nothing: white
		-- binary: white
		-- cell-path: white
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

	add_all_groups_with_prefix("@nu-", nu_group_to_group)

	do
		local consts_to_make <const> = {}
		local seen_vars <const> = {}
		for _, v in pairs(nu_group_to_group) do
			if not seen_vars[v] then
				seen_vars[v] = true
				local color <const> = assert(groups[v], "No group named " .. v)
				local var_value <const> = { "{" }
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

		table.sort(consts_to_make, function(a: {string}, b: {string}): boolean return a[1] < b[1] end)

		for _, v in ipairs(consts_to_make) do
			ins("const ", v[1], " = ", v[2])
		end
	end

	local p = {}
	for k, v in pairs(nu_group_to_group) do
		table.insert(p, { k, v })
	end
	table.sort(p, function(a: {string}, b: {string}): boolean return a[1] < b[1] end)

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

local function swap<A, B>(a: A, b: B): B, A return b, a end

local function generate_css(): string
	local lines <const> = {}

	for name, entry in pairs(palette) do
		table.insert(lines, string.format("--palette-%s-dark: #%s;", name, entry.dark))
		table.insert(lines, string.format("--palette-%s-normal: #%s;", name, entry.normal))
		table.insert(lines, string.format("--palette-%s-bright: #%s;", name, entry.bright))
	end

	for k, v in pairs(groups) do
		if k:sub(1, 7) == "syntax-" then
			table.insert(
				lines,
				string.format(".%s { color: var(--palette-%s-%s); }", k, swap(v.foreground:match("(%w+)%.(%w+)") as (string, string)))
			)
		end
	end

	table.sort(lines)

	return table.concat(lines, "\n")
end

local function generate_c23_header(): string
	local lines <const> = {}
	local function line(fmt: string, ...)
		table.insert(lines, string.format(fmt, ...))
	end

	for _, name in ipairs(palette_names) do
		local entry <const> = palette[name]
		line("constexpr theme_rgb palette_%s_dark = 0x%s;", name, entry.dark)
		line("constexpr theme_rgb palette_%s_normal = 0x%s;", name, entry.normal)
		line("constexpr theme_rgb palette_%s_bright = 0x%s;", name, entry.bright)
	end

	local function palette_name(group_entry: string): string
		if not group_entry then
			return "theme_nil"
		end
		return ("palette_%s_%s"):format(swap(split_on(group_entry, ".")))
	end

	for _, name in ipairs(group_names) do
		if name:sub(1, 1) ~= "@" then
			local group <const> = groups[name]
			line(
				"constexpr theme_entry theme_%s = { %s, %s, %s };",
				name:gsub("%-", "_"),
				palette_name(group.foreground),
				palette_name(group.background),
				group.extra == "emphasis" and "theme_emphasis" or "0"
			)
		end
	end

	return
		"#ifndef THEME_H\n"
		.. "#define THEME_H\n"
		.. "#include <stdint.h>\n"
		.. "typedef uint32_t theme_rgb;\n"
		.. "constexpr theme_rgb theme_nil = 0xffffffff;\n"
		.. "constexpr unsigned theme_emphasis = 1;\n"
		.. "struct { theme_rgba foreground, background; unsigned extra_flags; } typedef theme_entry;\n"
		.. table.concat(lines, "\n")
		.. "\n#endif // THEME_H\n"
end

local function generate_ppm(): string
	local buf <const> = { "P6\n5 11\n255\n" }

	for _, row in ipairs{
		"bg", "fg",
		"purple", "red", "magenta",
		"orange", "yellow", "green",
		"blue", "cyan", "gray",
	} do
		for _, col in ipairs{"dark","normal","bright"} do
			local str <const> = palette[row][col]
			local r <const> = tonumber(str:sub(1, 2), 16)
			local g <const> = tonumber(str:sub(3, 4), 16)
			local b <const> = tonumber(str:sub(5, 6), 16)
			table.insert(buf, string.char(r, g, b))
		end
	end

	return table.concat(buf)
end

local to_generate <const>, tsv = ...
groups = tsv and parse_tsv(tsv) or parse_tsv "group-names.tsv"
group_names = ordered_keys(groups)

local actions <const>: {string:function(): string} = {
	vim = generate_vim_colorscheme,
	nu = generate_nushell_colorscheme,
	css = generate_css,
	ansi = generate_ansi,
	pmm = generate_ppm,
	["c23-header"] = generate_c23_header,
}

local function actions_list(): string
	local keys <const> = {}
	for k in pairs(actions) do table.insert(keys, "‘" .. k .. "’") end
	table.sort(keys)
	return table.concat(keys, ", ")
end

if not to_generate then
	io.stderr:write("Usage: generate.lua <target>\n   target: one of ", actions_list(), "\n")
	os.exit(1)
elseif actions[to_generate] then
	print(actions[to_generate]())
else
	io.stderr:write(("Unknown target “%s”\n   Expected one of "):format(to_generate), actions_list())
	os.exit(1)
end
