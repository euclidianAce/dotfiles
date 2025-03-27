use std

def --env replace-home-with-tilde []: string -> string {
	let home = $env.HOME
	if $in == $home { return "~" }
	$in | str replace -r ("^" + $home + "/") "~/"
}

$env.PROMPT_COMMAND = {||
	let prompt = ($env.DOTFILE_DIR | path join prompt)
	let exit_code = if $env.LAST_EXIT_CODE == 0 {
		""
	} else {
		$"罰 ($env.LAST_EXIT_CODE)"
	}

	mut current_git_head = try { run-external "git" "branch" "--show-current" e> (std null-device) } catch { "" }
	if $current_git_head == "" {
		$current_git_head = try { run-external "git" "rev-parse" "--short" "HEAD" e> (std null-device) } catch { "" }
	}
	if $current_git_head != "" {
		$current_git_head = "* " + $current_git_head
	}

	let working_directory = $env.PWD | replace-home-with-tilde

	let tmux_status = if env.TMUX? != null { "" } else { "not in tmux" }

	let nix_shell_status = match $env.IN_NIX_SHELL? {
		null => ""
		$x => $"nix: ($x)"
	}

	let ssh_status = if $env.SSH_CLIENT? != null { "(ssh) " } else { "" }

	let shell_depth = match ($env.SHLVL? | default 0 | into int) {
		0 => ""
		$x => $"Nested shell ($x)"
	}

	let is_root = try { ^id -u | into int | $in == 0 } catch { false }
	let line_color = if $is_root { "red" } else { "cyan" }
	let prompt_str = if $is_root { "# " } else { "$ " }
	let prompt_color = if $is_root { "red" } else { "magenta" }

	(
		run-external
		$prompt
		("line_color=" + $line_color)
		("prompt=" + $prompt_str)
		("prompt_color=" + $prompt_color)
		attr=red $exit_code
		attr=bright_yellow $shell_depth
		attr=yellow $tmux_status
		attr=gray (run-external date '+%I:%M:%S %p')
		attr=red $"($ssh_status)($env.USER)@(^hostname)"
		attr=blue pad=10 $working_directory
		attr=green $nix_shell_status
		attr=bright_green $current_git_head
	)
}

$env.PROMPT_COMMAND_RIGHT = ""

$env.PROMPT_INDICATOR = ""
$env.PROMPT_INDICATOR_VI_INSERT = "(i) "
$env.PROMPT_INDICATOR_VI_NORMAL = "(n) "
$env.PROMPT_MULTILINE_INDICATOR = " │ "

$env.NU_LIB_DIRS = [
	($nu.default-config-dir | path join 'scripts')
	$nu.default-config-dir
]

$env.NU_PLUGIN_DIRS = [
	($nu.default-config-dir | path join 'plugins')
]

$env.EDITOR = if $env.NVIM? != null { "nvim --server " + $env.NVIM + " --remote" } else { "nvim" }
$env.MANPAGER = if $env.NVIM? != null { "less" } else { "nvim +Man!" }
if $env.DOTFILE_DIR? == null {
	$env.DOTFILE_DIR = ($env.HOME | path join "dotfiles")
}
