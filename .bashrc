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
alias rm="rm -v"
alias ls="ls -hN   --file-type --color=auto --group-directories-first"
alias la="ls -AhN  --file-type --color=auto --group-directories-first"
alias ll="ls -AhNl --file-type --color=auto --group-directories-first"
alias grep="grep --color=auto"
alias nd="nix develop"

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
	local kind=$(stat -c %F "$1")
	if [[ "$kind" == "directory" ]]; then
		ls "$1"
	elif [[ -n "$kind" ]]; then
		cat "$1"
	else
		return 1
	fi
}

alias sdn="sudo shutdown -h now"
alias rb="sudo reboot"

####################
#### PS1 STUFFS ####
####################

SET_DEFAULT_PS1=0
export MY_PS1=$PS1
export PS2=" \[\e[90m\]│\[\e[0m\]  "
ps1swap () {
	SET_DEFAULT_PS1=$((1-$SET_DEFAULT_PS1))
}
update_ps1 () {
	local last_exit_code="$?"
	if (( $SET_DEFAULT_PS1 == 1 )); then
		PS1=$MY_PS1
		return 0
	fi

	PS1=$($DOTFILE_DIR/ps1-bash $last_exit_code 2> /tmp/ps1ErrLog.log)
	if [ "$PS1" = "" ]; then
		PS1=$MY_PS1
	fi
}
update_ps1
PROMPT_COMMAND=update_ps1
