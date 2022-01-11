
    ######                  #
    ##   ##                 #
    ##   ##  ####    ###### # ###   # ####   #####
    ######       #  #       ##   #  ##    # #     #
    ##   ##  ####    #####  #     # #       #
##  ##   ## #   ##        # #     # #       #     #
##  ######   ###  # ######  #     # #        #####

# cursor blink
echo -ne "\x1b[\x30 q"

find-detached-session () {
	local s=$(tmux ls 2>/dev/null | awk -F':' '!/\(attached\)$/{print $1}' | head -n 1)
	if [[ -z "$s" ]]; then
		echo "tmux"
	else
		echo "tmux attach -t $s"
	fi
}

if [[ -z $TMUX && -z $NO_TMUX ]]; then
	exec $(find-detached-session)
fi

shopt -s autocd # Automatically does a cd when you type a directory
shopt -s checkwinsize # resize window automatically after each command

#################
#### HISTORY ####
#################

export HISTFILESIZE=20000
export HISTSIZE=10000
shopt -s histappend
HISTCONTROL=ignoredups
export HISTIGNORE="&:ls:[bf]g:clear:exit:.."

##########################
#### ENVIRONMENT VARS ####
##########################

# for some reason this doesnt seem to be set by default...
export XDG_CONFIG_HOME="$HOME/.config"
export DOTFILE_DIR="$HOME/dotfiles"

# set nvim as the default editor
export EDITOR="nvim"
export MANPAGER="nvim +Man!"

export LUA_CPATH+=";$HOME/dev/luastuffs/ltreesitter/?.so;$HOME/dev/parsers/?.so"
if ! [[ "$SHELL" =~ /nix/store.* ]]; then
	export PATH+=":./:$HOME/Applications:$HOME/bin:/usr/local/bin"
fi

# xterm-kitty doesn't work over ssh
# export TERM=xterm-256color

#################
#### ALIASES ####
#################

export PATH="$DOTFILE_DIR/bin/:$PATH"

alias ls="ls -hN   --file-type --color=auto --group-directories-first"
alias la="ls -AhN  --file-type --color=auto --group-directories-first"
alias ll="ls -AhNl --file-type --color=auto --group-directories-first"
alias grep="grep --color=auto"

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

envrc () {
	$EDITOR +'cd $DOTFILE_DIR/nvim/' +'Telescope find_files'
}

## Git

alias gs="git status --short"
alias gsl="git status"

alias gd="git diff"
alias gdt="git difftool -y"

ga () {
	git add $@
	git status --short
}
alias gaa="git add -A; git status --short"
alias gap="git add -p"
alias gc="git commit"
alias gcm="git commit -m"

alias gpush="git push"
alias gpushu="git push -u"
alias gpull="git pull"

alias gl="git log --graph --decorate --oneline"
alias gll="git log --graph --decorate"

## Package manager aliases
distro=$(awk -F= '/^ID=.*$/{print $2}' /etc/*-release | cut --delimiter='"' -f 2)

case "$distro" in
	"gentoo")
		# always ask before emerging and do it quietly
		alias emerge="sudo emerge --ask --quiet"
		alias emergev="sudo emerge --ask"
		alias emergef="sudo emerge --ask --fetchonly --quiet"
		alias etc-update="sudo etc-update"

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
	"nixos")
		function nixsh {
			nix-shell "$HOME/shells/$1.nix"
		}
		;;
esac

## editing
e () {
	if [[ "$FLOATTERM" = "1" ]]; then
		nano $@
	else
		$EDITOR $@
	fi
}

alias v="vim"
alias nv="nvim"

mkcd () {
	mkdir -p "$1" && cd "$1"
}

alias sdn="sudo shutdown -h now"
alias rb="sudo reboot"
alias reboot="sudo reboot"

####################
#### PS1 STUFFS ####
####################

# offload getting ps1 to script
SET_DEFAULT_PS1=0
export MY_PS1=$PS1
export PS2=" \[\e[90m\]│\[\e[0m\] "
ps1swap () {
	SET_DEFAULT_PS1=$((1-$SET_DEFAULT_PS1))
}
update_ps1 () {
	if (( $SET_DEFAULT_PS1 == 1 )); then
		PS1=$MY_PS1
		return 0
	fi

	PS1=$($DOTFILE_DIR/ps1-bash 2> /tmp/ps1ErrLog.log)
	if [ "$PS1" = "" ]; then
		PS1=$MY_PS1
	fi
}
update_ps1
PROMPT_COMMAND=update_ps1
