use std

export def e [...arguments] {
	run-external $env.EDITOR ...$arguments
}

export def gs [--long] {
	if $long {
		^git status
	} else {
		^git status --short
	}
}

export def ga [...arguments] {
	^git add ...$arguments
	^git status --short
}

export def gc [] { ^git commit --verbose }
export def gl [--long] {
	if $long {
		^git log --graph --decorate
	} else {
		^git log --graph --format='%C(auto)%h %<(15)%ar %d %s'
	}
}

export def --env mkcd [directory: path] {
	mkdir -v $directory
	cd $directory
}

export def tmux-sessions [] {
	^tmux list-sessions -F '#{session_name},#{?session_attached,true,false}' err> (std null-device)
		| from csv --noheaders
		| rename session_name is_attached
		| update is_attached { into bool }
}

export def tmux-new-or-attach [] {
	let unattached_session_name = tmux-sessions
		| where is_attached == false
		| get 0?.session_name
	if $unattached_session_name == null {
		^tmux
	} else {
		^tmux attach -t $unattached_session_name
	}
}
