use std

export def e [...arguments] {
	run-external $env.EDITOR ...$arguments
}

export def gs [--long (-l)] {
	let flag = if $long { "" } else { "--short" }
	^git status $flag
}

export def ga [...arguments] {
	^git add ...$arguments
	^git status --short
}

export def gc [--quiet (-q)] {
	let flag = if $quiet { "" } else { "--verbose" }
	^git commit $flag
}

export def gl [--long (-l)] {
	let arg = if $long {
		"--decorate"
	} else {
		# note, we dont need quotes after the = here since it will be passed as a string
		"--format=%C(auto)%h %<(15)%ar %d %s"
	}
	^git log --graph $arg
}

export def gd [] { ^git diff }

export def --env mkcd [directory: path] {
	mkdir -v $directory
	cd $directory
}

export def throttle [
	--limit (-l): int
	--verbose (-v)
	...rest
] {
	let v = if $verbose { "--verbose" } else { "--quiet" }
	^cpulimit $v --foreground --monitor-forks --limit $limit -- ...$rest
}
