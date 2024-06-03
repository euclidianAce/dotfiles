const bright_text_color = { fg: "#AAC3FD" }
const error_color = { fg: "#E69090" }
const hint_color = { fg: "#EFEFEF" }
const nu_filepath_color = { fg: "#70C3C6" }
const nu_filesize_color = { fg: "#429DA0" }
const nu_header_color = { fg: "#7BCE8F" }
const nu_row_index_color = { fg: "#7BCE8F" }
const paren_matching_color = { fg: "#181520" bg: "#FFC590" }
const searched_selected_highlighted_text_color = { fg: "#16131F" bg: "#E69090" }
const syntax_delimiter_color = { fg: "#817998" }
const syntax_keyword_color = { fg: "#799AE0" }
const syntax_literal_color = { fg: "#D16161" }
const syntax_operator_color = { fg: "#9876D9" }
const syntax_string_escape_color = { fg: "#E69090" }
const syntax_type_color = { fg: "#C7B1F2" }
const text_color = { fg: "#D8CEE4" }
export const theme = {
	bool: $syntax_literal_color
	date: $syntax_literal_color
	duration: $syntax_literal_color
	filepath: $nu_filepath_color
	filesize: $nu_filesize_color
	float: $syntax_literal_color
	header: $nu_header_color
	hints: $hint_color
	int: $syntax_literal_color
	row_index: $nu_row_index_color
	search_result: $searched_selected_highlighted_text_color
	separator: $syntax_delimiter_color
	shape_and: $syntax_operator_color
	shape_binary: $syntax_operator_color
	shape_bool: $syntax_literal_color
	shape_external: $bright_text_color
	shape_externalarg: $text_color
	shape_flag: $syntax_literal_color
	shape_float: $syntax_literal_color
	shape_garbage: $error_color
	shape_int: $syntax_literal_color
	shape_keyword: $syntax_keyword_color
	shape_literal: $syntax_literal_color
	shape_matching_brackets: $paren_matching_color
	shape_operator: $syntax_operator_color
	shape_or: $syntax_operator_color
	shape_pipe: $syntax_operator_color
	shape_range: $syntax_operator_color
	shape_redirection: $syntax_operator_color
	shape_signature: $syntax_type_color
	shape_string: $bright_text_color
	shape_string_interpolation: $syntax_string_escape_color
	shape_vardecl: $syntax_type_color
	shape_variable: $syntax_type_color
	string: $bright_text_color
}
