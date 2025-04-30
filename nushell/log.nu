export const info_color = (ansi cyan)
export const warn_color = (ansi yellow)
export const error_color = (ansi red)

const reset = (ansi reset)

def do-log [
	color,
	prefix,
	--no-newline,
	...args
] {
	let lines = ($args | each { into string } | str join | lines)
	print --no-newline $color $prefix $reset $lines.0
	for line in ($lines | skip 1) {
		print --no-newline $color "\n     ... "  $reset $line
	}
	if not $no_newline {
		print --no-newline "\n"
	}
}

export def --env info [--no-newline, ...args] {
	do-log $info_color "  [Info] " --no-newline=$no_newline ...$args
}

export def --env warn [--no-newline, ...args] {
	do-log $warn_color "  [Warn] " --no-newline=$no_newline ...$args
}

export def --env error [--no-newline, ...args] {
	do-log $error_color " [Error] " --no-newline=$no_newline ...$args
}
