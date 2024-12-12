use theme.nu theme
use keys.nu keys
source commands.nu
use log.nu
use tmux.nu

$env.config = {
	show_banner: false

	ls: {
		use_ls_colors: true
		clickable_links: true
	}

	rm: {
		always_trash: true
	}

	table: {
		mode: rounded # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
		index_mode: always
		show_empty: true
		padding: { left: 1, right: 1 }
		trim: {
			methodology: wrapping
			wrapping_try_keep_words: true
			truncating_suffix: "..."
		}
		header_on_separator: false # show header text on separator/border line
		# abbreviated_row_count: 10 # limit data rows from top and bottom after reaching a set point
	}

	error_style: "fancy"

	datetime_format: {
		# normal: '%a, %d %b %Y %H:%M:%S %z' # shows up in displays of variables or other datetime's outside of tables
		# table: '%m/%d/%y %I:%M:%S%p' # generally shows up in tabular outputs such as ls. commenting this out will change it to the default human readable datetime format
	}

	explore: {
		status_bar_background: {fg: "#1D1F21", bg: "#C4C9C6"},
		command_bar_text: {fg: "#C4C9C6"},
		highlight: {fg: "black", bg: "yellow"},
		status: {
			error: {fg: "white", bg: "red"},
			warn: {}
			info: {}
		},
		table: {
			split_line: {fg: "#404040"},
			selected_cell: {bg: light_blue},
			selected_row: {},
			selected_column: {},
		},
	}

	history: {
		max_size: 100_000
		sync_on_enter: true
		file_format: "plaintext"
		isolation: false
	}

	completions: {
		case_sensitive: false
		quick: true
		partial: true
		algorithm: "fuzzy"
		external: {
			enable: true
			max_results: 100
			completer: null
		}
	}

	filesize: {
		metric: false # true => KB, MB, GB (ISO standard), false => KiB, MiB, GiB (Windows standard)
		format: "auto" # b, kb, kib, mb, mib, gb, gib, tb, tib, pb, pib, eb, eib, auto
	}

	cursor_shape: {
		emacs: block # block, underscore, line, blink_block, blink_underscore, blink_line, inherit to skip setting cursor shape (line is the default)
		vi_insert: block # block, underscore, line, blink_block, blink_underscore, blink_line, inherit to skip setting cursor shape (block is the default)
		vi_normal: underscore # block, underscore, line, blink_block, blink_underscore, blink_line, inherit to skip setting cursor shape (underscore is the default)
	}

	color_config: $theme
	footer_mode: auto # always, never, number_of_rows, auto
	float_precision: 2
	buffer_editor: ""
	use_ansi_coloring: true
	bracketed_paste: true
	edit_mode: emacs
	render_right_prompt_on_last_line: false
	use_kitty_protocol: false

	hooks: {
		pre_prompt: [{ null }]
		pre_execution: [{ null }]
		env_change: {}
		display_output: "if (term size).columns >= 100 { table -e } else { table }" # run to display the output of a pipeline
		command_not_found: { null }
	}

	menus: [
		# Configuration for default nushell menus
		# Note the lack of source parameter
		{
			name: completion_menu
			only_buffer_difference: false
			marker: "| "
			type: {
				layout: columnar
				columns: 4
				col_width: 20	 # Optional value. If missing all the screen width is used to calculate column width
				col_padding: 2
			}
			style: {
				text: green
				selected_text: green_reverse
				description_text: yellow
			}
		}
		{
			name: help_menu
			only_buffer_difference: true
			marker: "? "
			type: {
				layout: description
				columns: 4
				col_width: 20	 # Optional value. If missing all the screen width is used to calculate column width
				col_padding: 2
				selection_rows: 4
				description_rows: 10
			}
			style: {
				text: green
				selected_text: green_reverse
				description_text: yellow
			}
		}
	]

	keybindings: $keys
}
