use std

def --env replace-home-with-tilde [p: string] -> string {
	let home = $env.HOME
	if $p == $home { return "~" }
	$p | str replace -r ("^" + $home + "/") "~/"
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

	let working_directory = replace-home-with-tilde $env.PWD

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

let path_conversion = {
	from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
		     to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
}

$env.ENV_CONVERSIONS = {
	"PATH": path_conversion
	"Path": path_conversion
}

$env.NU_LIB_DIRS = [
	($nu.default-config-dir | path join 'scripts')
	$nu.default-config-dir
]

$env.NU_PLUGIN_DIRS = [
	($nu.default-config-dir | path join 'plugins')
]

$env.EDITOR = "nvim"
$env.MANPAGER = "nvim +Man!"
$env.DOTFILE_DIR = ($env.HOME | path join "dotfiles")
