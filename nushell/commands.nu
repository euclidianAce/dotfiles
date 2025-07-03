# Invokes $EDITOR with the given arguments
export def --wrapped e [...arguments: path] {
	# accomodate pre v0.102
	let cmd = [...($env.EDITOR | split row ' ') ...($arguments | path expand)]
	run-external ($cmd | first) ...($cmd | skip 1)
}

# git status --short
export def --wrapped gs [--long (-l), ...rest] {
	let flag = if $long { "" } else { "--short" }
	^git status $flag ...$rest
}

# git switch
export def --wrapped gsw [...rest] {
	^git switch ...$rest
}

# git add, then git status
export def --wrapped ga [...arguments] {
	^git add ...$arguments
	^git status --short
}

# git commit
export def --wrapped gc [--quiet (-q), ...rest] {
	let flag = if $quiet { "" } else { "--verbose" }
	^git commit $flag ...$rest
}

# git log --format=...
export def --wrapped gl [--long (-l), ...rest] {
	let arg = if $long {
		"--decorate"
	} else {
		# note, we dont need quotes after the = here since it will be passed as a string
		"--format=%C(auto)%h %<(15)%ar %d %s"
	}
	^git log --graph $arg ...$rest
}

# git diff
export def --wrapped gd [...rest] { ^git diff ...$rest }

# Make a directory and immediately `cd` into it
export def --env mkcd [directory: path] {
	mkdir -v $directory # nushell mkdir doesn't need -p
	cd $directory
}

# Use `cpulimit` to keep a command from taking over the cpu
export def --wrapped throttle [
	--limit (-l): int
	--verbose (-v)
	...rest
] {
	let v = if $verbose { "--verbose" } else { "--quiet" }
	^cpulimit $v --foreground --monitor-forks --limit $limit -- ...$rest
}

# Enter a nested `nu` instance via `doas` with the current config,
export def --env root-shell [] {
	doas $nu.current-exe --no-history --config $nu.config-path --env-config $nu.env-path
}

def extensions []: string -> list<string> {
	let arr = split row '.'
	let len = $arr | length
	1..($len - 1) | reduce --fold [] {|it, acc|
		$acc | append (
			$arr | skip ($len - $it) | str join '.'
		)
	}
}

export def extract [
	archive: path
	--format: string
	--verbose (-v)
	--dry-run
] {
	let exts = if $format != null {
		[$format]
	} else {
		$archive | extensions
	}

	for extension in $exts {
		let cmd = match $extension {
			"tar.xz" => ["tar" ("Jxf" | if $verbose { "v" + $in } else { $in }) $archive]
			"tar.gz" => ["tar" ("zxf" | if $verbose { "v" + $in } else { $in }) $archive]
			"tar" => ["tar" ("xf" | if $verbose { "v" + $in } else { $in }) $archive]
			"xz" => { ["xz" "-d"] | if $verbose { $in | append "-v" } else { $in } | append $archive }
			"gzip" => { ["gunzip"] | if $verbose { $in | append "-v" } else { $in } | append $archive }
			"zip" => ["unzip" $archive]

			_ => continue
		}

		if $dry_run {
			print $cmd
		} else {
			run-external $cmd.0 ...($cmd | skip 1)
		}
		return
	}

	if $format != null {
		error make {
			msg: $"Unknown format ‘($format)’"
			span: (metadata $format).span
		}
	} else {
		error make {
			msg: $"Unable to determine format of archive ‘($archive)’, use --format to specify"
			span: (metadata $archive).span
		}
	}
}
