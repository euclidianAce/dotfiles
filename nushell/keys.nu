export const keys = [
	{
		name: completion_menu
		modifier: none
		keycode: tab
		mode: [emacs vi_normal vi_insert]
		event: {
			until: [
				{ send: menu name: completion_menu }
				{ send: menunext }
				{ edit: complete }
			]
		}
	}
	{
		name: fzf_history
		modifier: control
		keycode: char_r
		mode: [emacs, vi_insert, vi_normal]
		event: {
			send: executehostcommand
			cmd: "commandline edit (
				history
				| get command
				| uniq
				| reverse
				| str join (char -i 0)
				| fzf --read0 --tiebreak=chunk --layout=reverse --height=70% --border=rounded
				| decode utf-8
				| str trim
			)"
		}
	}
	{
		name: fzf_find_file
		modifier: control
		keycode: char_f
		mode: [emacs, vi_insert]
		event: {
			send: executehostcommand
			cmd: "commandline edit (
				run-external 'find' '.' '-type' 'f'
				| lines
				| str join (char -i 0)
				| fzf --read0 --tiebreak=chunk --layout=reverse --height=70% --border=rounded
				| decode utf-8
				| str trim
				| do {
					let line = (commandline)
					let cursor_pos = (commandline get-cursor)
					let before = $line | str substring 0..($cursor_pos - 1)
					let after = $line | str substring $cursor_pos..
					$before + $in + $after
				}
			)"
		}
	}
	{
		name: help_menu
		modifier: none
		keycode: f1
		mode: [emacs, vi_insert, vi_normal]
		event: { send: menu name: help_menu }
	}
	{
		name: completion_previous_menu
		modifier: shift
		keycode: backtab
		mode: [emacs, vi_normal, vi_insert]
		event: { send: menuprevious }
	}
	{
		name: next_page_menu
		modifier: control
		keycode: char_x
		mode: emacs
		event: { send: menupagenext }
	}
	{
		name: undo_or_previous_page_menu
		modifier: control
		keycode: char_z
		mode: emacs
		event: {
			until: [
				{ send: menupageprevious }
				{ edit: undo }
			]
		}
	}
	{
		name: escape
		modifier: none
		keycode: escape
		mode: [emacs, vi_normal, vi_insert]
		event: { send: esc }		# NOTE: does not appear to work
	}
	{
		name: cancel_command
		modifier: control
		keycode: char_c
		mode: [emacs, vi_normal, vi_insert]
		event: { send: ctrlc }
	}
	{
		name: quit_shell
		modifier: control
		keycode: char_d
		mode: [emacs, vi_normal, vi_insert]
		event: { send: ctrld }
	}
	{
		name: clear_screen
		modifier: control
		keycode: char_l
		mode: [emacs, vi_normal, vi_insert]
		# Using the clear command instead of:
		#   event: { send: clearscreen }
		# redraws the prompt, so if I shrink a terminal in the middle
		# of typing something, I can resize the prompt
		event: {
			send: executehostcommand
			cmd: "clear"
		}
	}
	{
		name: search_history
		modifier: control
		keycode: char_q
		mode: [emacs, vi_normal, vi_insert]
		event: { send: searchhistory }
	}
	{
		name: open_command_editor
		modifier: control
		keycode: char_o
		mode: [emacs, vi_normal, vi_insert]
		event: { send: openeditor }
	}
	{
		name: move_up
		modifier: none
		keycode: up
		mode: [emacs, vi_normal, vi_insert]
		event: {
			until: [
				{send: menuup}
				{send: up}
			]
		}
	}
	{
		name: move_down
		modifier: none
		keycode: down
		mode: [emacs, vi_normal, vi_insert]
		event: {
			until: [
				{send: menudown}
				{send: down}
			]
		}
	}
	{
		name: move_left
		modifier: none
		keycode: left
		mode: [emacs, vi_normal, vi_insert]
		event: {
			until: [
				{send: menuleft}
				{send: left}
			]
		}
	}
	{
		name: move_right_or_take_history_hint
		modifier: none
		keycode: right
		mode: [emacs, vi_normal, vi_insert]
		event: {
			until: [
				{send: historyhintcomplete}
				{send: menuright}
				{send: right}
			]
		}
	}
	{
		name: move_one_word_left
		modifier: control
		keycode: left
		mode: [emacs, vi_normal, vi_insert]
		event: {edit: movewordleft}
	}
	{
		name: move_one_word_right_or_take_history_hint
		modifier: control
		keycode: right
		mode: [emacs, vi_normal, vi_insert]
		event: {
			until: [
				{send: historyhintwordcomplete}
				{edit: movewordright}
			]
		}
	}
	{
		name: move_to_line_start
		modifier: none
		keycode: home
		mode: [emacs, vi_normal, vi_insert]
		event: {edit: movetolinestart}
	}
	{
		name: move_to_line_start
		modifier: control
		keycode: char_a
		mode: [emacs, vi_normal, vi_insert]
		event: {edit: movetolinestart}
	}
	{
		name: move_to_line_end_or_take_history_hint
		modifier: none
		keycode: end
		mode: [emacs, vi_normal, vi_insert]
		event: {
			until: [
				{send: historyhintcomplete}
				{edit: movetolineend}
			]
		}
	}
	{
		name: move_to_line_end_or_take_history_hint
		modifier: control
		keycode: char_e
		mode: [emacs, vi_normal, vi_insert]
		event: {
			until: [
				{send: historyhintcomplete}
				{edit: movetolineend}
			]
		}
	}
	{
		name: move_to_line_start
		modifier: control
		keycode: home
		mode: [emacs, vi_normal, vi_insert]
		event: {edit: movetolinestart}
	}
	{
		name: move_to_line_end
		modifier: control
		keycode: end
		mode: [emacs, vi_normal, vi_insert]
		event: {edit: movetolineend}
	}
	{
		name: move_up
		modifier: control
		keycode: char_p
		mode: [emacs, vi_normal, vi_insert]
		event: {
			until: [
				{send: menuup}
				{send: up}
			]
		}
	}
	{
		name: move_down
		modifier: control
		keycode: char_t
		mode: [emacs, vi_normal, vi_insert]
		event: {
			until: [
				{send: menudown}
				{send: down}
			]
		}
	}
	{
		name: delete_one_character_backward
		modifier: none
		keycode: backspace
		mode: [emacs, vi_insert]
		event: {edit: backspace}
	}
	{
		name: delete_one_word_backward
		modifier: control
		keycode: backspace
		mode: [emacs, vi_insert]
		event: {edit: backspaceword}
	}
	{
		name: delete_one_character_forward
		modifier: none
		keycode: delete
		mode: [emacs, vi_insert]
		event: {edit: delete}
	}
	{
		name: delete_one_character_forward
		modifier: control
		keycode: delete
		mode: [emacs, vi_insert]
		event: {edit: delete}
	}
	{
		name: delete_one_character_forward
		modifier: control
		keycode: char_h
		mode: [emacs, vi_insert]
		event: {edit: backspace}
	}
	{
		name: delete_one_word_backward
		modifier: control
		keycode: char_w
		mode: [emacs, vi_insert]
		event: {edit: backspaceword}
	}
	{
		name: move_left
		modifier: none
		keycode: backspace
		mode: vi_normal
		event: {edit: moveleft}
	}
	{
		name: newline_or_run_command
		modifier: none
		keycode: enter
		mode: emacs
		event: {send: enter}
	}
	{
		name: move_left
		modifier: control
		keycode: char_b
		mode: emacs
		event: {
			until: [
				{send: menuleft}
				{send: left}
			]
		}
	}
	{
		name: redo_change
		modifier: control
		keycode: char_g
		mode: emacs
		event: {edit: redo}
	}
	{
		name: undo_change
		modifier: control
		keycode: char_z
		mode: emacs
		event: {edit: undo}
	}
	{
		name: paste_before
		modifier: control
		keycode: char_y
		mode: emacs
		event: {edit: pastecutbufferbefore}
	}
	{
		name: cut_word_left
		modifier: control
		keycode: char_w
		mode: emacs
		event: {edit: cutwordleft}
	}
	{
		name: cut_line_to_end
		modifier: control
		keycode: char_k
		mode: emacs
		event: {edit: cuttoend}
	}
	{
		name: cut_line_from_start
		modifier: control
		keycode: char_u
		mode: emacs
		event: {edit: cutfromstart}
	}
	{
		name: swap_graphemes
		modifier: control
		keycode: char_t
		mode: emacs
		event: {edit: swapgraphemes}
	}
	{
		name: move_one_word_left
		modifier: alt
		keycode: left
		mode: emacs
		event: {edit: movewordleft}
	}
	{
		name: move_one_word_right_or_take_history_hint
		modifier: alt
		keycode: right
		mode: emacs
		event: {
			until: [
				{send: historyhintwordcomplete}
				{edit: movewordright}
			]
		}
	}
	{
		name: move_one_word_left
		modifier: alt
		keycode: char_b
		mode: emacs
		event: {edit: movewordleft}
	}
	{
		name: move_one_word_right_or_take_history_hint
		modifier: alt
		keycode: char_f
		mode: emacs
		event: {
			until: [
				{send: historyhintwordcomplete}
				{edit: movewordright}
			]
		}
	}
	{
		name: delete_one_word_forward
		modifier: alt
		keycode: delete
		mode: emacs
		event: {edit: deleteword}
	}
	{
		name: delete_one_word_backward
		modifier: alt
		keycode: backspace
		mode: emacs
		event: {edit: backspaceword}
	}
	{
		name: delete_one_word_backward
		modifier: alt
		keycode: char_m
		mode: emacs
		event: {edit: backspaceword}
	}
	{
		name: cut_word_to_right
		modifier: alt
		keycode: char_d
		mode: emacs
		event: {edit: cutwordright}
	}
	{
		name: upper_case_word
		modifier: alt
		keycode: char_u
		mode: emacs
		event: {edit: uppercaseword}
	}
	{
		name: lower_case_word
		modifier: alt
		keycode: char_l
		mode: emacs
		event: {edit: lowercaseword}
	}
	{
		name: capitalize_char
		modifier: alt
		keycode: char_c
		mode: emacs
		event: {edit: capitalizechar}
	}
]
