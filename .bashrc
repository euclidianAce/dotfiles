if [[ "$(tty)" =~ ^/dev/tty ]]; then
	# Don't auto start tmux in non pseudo tty
	export NO_TMUX=1
fi

TMUX_COMMAND="tmux"
# TMUX_COMMAND="env TERM=screen-256color tmux"

find-detached-session () {
	local s=$($TMUX_COMMAND ls 2>/dev/null | awk -F':' '!/\(attached\)$/{print $1}' | head -n 1)
	if [[ -z "$s" ]]; then
		echo "$TMUX_COMMAND"
	else
		echo "$TMUX_COMMAND attach -t $s"
	fi
}

if [[ -z $TMUX && -z $NO_TMUX ]]; then
	exec $(find-detached-session)
fi

echo -ne "\x1b[\x30 q"
shopt -s autocd
shopt -s globstar

#################
#### HISTORY ####
#################

export HISTFILESIZE=20000
export HISTSIZE=10000
shopt -s histappend
HISTCONTROL=ignoredups
export HISTIGNORE="&:l[sal]:[bf]g:clear:exit:..:sdn:rb:reboot:shutdown:[A"

##########################
#### ENVIRONMENT VARS ####
##########################

export XDG_CONFIG_HOME="$HOME/.config"
export DOTFILE_DIR="$HOME/dotfiles"

export EDITOR="nvim"
export MANPAGER="nvim +Man!"

export TRASH_DIRECTORY="$HOME/.trash"

export FZF_DEFAULT_COMMAND="$(which fd 2>/dev/null || echo find -type f)"

if ! [[ "$SHELL" =~ /nix/store.* ]]; then
	export PATH="./:$HOME/Applications:$HOME/bin:$HOME/bin/result/bin:/usr/local/bin:$DOTFILE_DIR/bin/:$PATH"
fi

#################
#### ALIASES ####
#################

alias mkdir="mkdir -v"
alias rmdir="rmdir -v"
alias mv="mv -v"
alias cp="cp -v"
alias ls="ls -hN   --file-type --color=auto --group-directories-first"
alias la="ls -AhN  --file-type --color=auto --group-directories-first"
alias ll="ls -AhNl --file-type --color=auto --group-directories-first"
alias grep="grep --color=auto"
alias nd="nix develop"

rm () {
	echo Nope. Use trash instead.
}

trash () {
	if [[ -z "$1" ]]; then
		return
	fi

	if ! [[ -d "$TRASH_DIRECTORY" ]]; then
		if [[ -a "$TRASH_DIRECTORY" ]]; then
			echo "[error] TRASH_DIRECTORY ($TRASH_DIRECTORY) exists but is not a folder" 1>&2
			return 1
		fi
		mkdir -p "$TRASH_DIRECTORY" || return 1
	fi

	mv -v "$1" "$TRASH_DIRECTORY/$(echo "$1" | sed 's,/,_,g').$(date '+%F')"
}

#stolen from fzf install script
__fzfcmd () {
	[ -n "$TMUX_PANE" ] && { [ "${FZF_TMUX:-0}" != 0 ] || [ -n "$FZF_TMUX_OPTS" ]; } &&
		echo "fzf-tmux ${FZF_TMUX_OPTS:--d${FZF_TMUX_HEIGHT:-40%}} -- " || echo "fzf"
}

__fzf_history__ () {
	local output
	output=$(
		builtin fc -lnr -2147483648 |
			last_hist=$(HISTTIMEFORMAT='' builtin history 1) perl -n -l0 -e 'BEGIN { getc; $/ = "\n\t"; $HISTCMD = $ENV{last_hist} + 1 } s/^[ *]//; print $HISTCMD - $. . "\t$_" if !$seen{$_}++' |
			FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort,ctrl-z:ignore $FZF_CTRL_R_OPTS +m --read0" $(__fzfcmd) --border --query "$READLINE_LINE"
	) || return
	READLINE_LINE=${output#*$'\t'}
	if [ -z "$READLINE_POINT" ]; then
		echo "$READLINE_LINE"
	else
		READLINE_POINT=0x7fffffff
	fi
}

bind -m emacs-standard -x '"\C-r": __fzf_history__'
bind -m vi-command -x '"\C-r": __fzf_history__'
bind -m vi-insert -x '"\C-r": __fzf_history__'

ebrc () {
	$EDITOR "$DOTFILE_DIR/.bashrc" && source ~/.bashrc
}

alias gs="git status --short"
alias gsl="git status"

alias gd="git diff"
alias gdt="git difftool -y"

ga () {
	git add $@
	git status --short
}
alias gaa="git add --all; git status --short"
alias gap="git add --patch"
alias gc="git commit --verbose"
alias gcm="git commit --message"
alias gl="git log --graph --format='%C(auto)%h %<(15)%ar %d %s'"
alias gll="git log --graph --decorate"

distro=$(awk -F= '/^ID=.*$/{print $2}' /etc/*-release | cut --delimiter='"' -f 2)

case "$distro" in
	"gentoo")
		# always ask before emerging and do it quietly
		alias emerge="sudo emerge --ask --quiet"
		alias emergev="sudo emerge --ask"
		alias emergef="sudo emerge --ask --fetchonly --quiet"
		alias emerges="emerge --search"

		# convenience for patches
		function patch-dir {
			cd "/etc/portage/patches/$1"
		}
		function ebuild-dir {
			cd "$(portageq get_repo_path / gentoo)/$1"
		}
		;;
	"void")
		alias xbps-update="sudo xbps-install -Su"
		alias xbpsi="sudo xbps-install"
		alias xbpsr="sudo xbps-remove"
		alias xbpsq="xbps-query -Rs"
		;;
esac

nixsh () {
	echo "entering nix shell for $DOTFILE_DIR/nix-shells/$1.nix"
	nix-shell "$DOTFILE_DIR/nix-shells/$1.nix"
}

e () {
	$EDITOR $@
}

mkcd () {
	mkdir -v -p "$1" && cd "$1"
}

lcat () {
	if [[ -d "$1" ]]; then
		ls "$1"
	else
		cat "$1"
	fi
}

alias sdn="sudo shutdown -h now"
alias rb="sudo reboot"

####################
#### PS1 STUFFS ####
####################

export PS2=" \[\e[90m\]│\[\e[0m\]  "
update_ps1 () {
	local last_exit_code="$?"
	PS1=$($DOTFILE_DIR/ps1-bash $last_exit_code 2> /tmp/ps1ErrLog.log)

	# local working_directory="$PWD"
	# if [[ "$working_directory" =~ ^$HOME(.*) ]]; then
	# 	working_directory="~${BASH_REMATCH[1]}"
	# fi
	# PS1=$($DOTFILE_DIR/prompt \
	# 	$([[ $last_exit_code == '0' ]] || echo "attr=red $last_exit_code") \
	# 	attr=gray "$(date '+%I:%M:%S %p')" \
	# 	attr=red "$USER@$(hostname)" \
	# 	attr=blue $working_directory \
	# 	attr=bright_green "$(git branch --show-current 2>/dev/null)")
}
update_ps1
PROMPT_COMMAND=update_ps1
