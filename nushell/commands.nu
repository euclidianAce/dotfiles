use std

export def --wrapped e [...arguments: path] {
	run-external ...($env.EDITOR | split row ' ') ...($arguments | path expand)
}

export def --wrapped gs [--long (-l), ...rest] {
	let flag = if $long { "" } else { "--short" }
	^git status $flag ...$rest
}

export def --wrapped ga [...arguments] {
	^git add ...$arguments
	^git status --short
}

export def --wrapped gc [--quiet (-q), ...rest] {
	let flag = if $quiet { "" } else { "--verbose" }
	^git commit $flag ...$rest
}

export def --wrapped gl [--long (-l), ...rest] {
	let arg = if $long {
		"--decorate"
	} else {
		# note, we dont need quotes after the = here since it will be passed as a string
		"--format=%C(auto)%h %<(15)%ar %d %s"
	}
	^git log --graph $arg ...$rest
}

export def --wrapped gd [...rest] { ^git diff ...$rest }

export def --env mkcd [directory: path] {
	mkdir -v $directory # nushell mkdir doesn't need -p
	cd $directory
}

export def --wrapped throttle [
	--limit (-l): int
	--verbose (-v)
	...rest
] {
	let v = if $verbose { "--verbose" } else { "--quiet" }
	^cpulimit $v --foreground --monitor-forks --limit $limit -- ...$rest
}
