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

	let tmux_status = if ($env | get TMUX?) != null { "" } else { "not in tmux" }

	let nix_shell_status = match ($env | get IN_NIX_SHELL?) {
		null => ""
		$x => $"nix: ($x)"
	}

	let ssh_status = if ($env | get SSH_CLIENT?) != null { "(ssh) " } else { "" }

	(
		run-external
		$prompt
		attr=red $exit_code
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
$env.DOTFILE_DIR = ($env.HOME | path join "dotfiles")

$env.SHELL_DEPTH = (($env.SHELL_DEPTH? | default 0) | into int) + 1
