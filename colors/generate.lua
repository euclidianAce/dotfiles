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

local function generate_vim_colorscheme()
	local lines = {
		"set background=dark",
		"let s:t_Co = &t_Co",
		"hi clear",
		"let g:colors_name = 'euclidian'"
	}

	local function ins(...)
		table.insert(lines, table.concat{...})
	end

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

	local function hi(vim_group_name, group)
		local buf = { "hi ", vim_group_name, " ctermfg=NONE ctermbg=NONE cterm=NONE" }

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
			io.stderr:write("No group named ", pair[2], " for vim group ", pair[1])
		end
	end

	table.insert(lines, "unlet s:t_Co")
	table.insert(lines, "finish")

	return table.concat(lines, "\n")
end

print(generate_vim_colorscheme())
