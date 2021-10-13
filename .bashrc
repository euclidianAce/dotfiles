
    ######                  #
    ##   ##                 #
    ##   ##  ####    ###### # ###   # ####   #####
    ######       #  #       ##   #  ##    # #     #
    ##   ##  ####    #####  #     # #       #
##  ##   ## #   ##        # #     # #       #     #
##  ######   ###  # ######  #     # #        #####


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
export TERM=xterm-256color

#################
#### ALIASES ####
#################

for f in $DOTFILE_DIR/bash_aliases/*; do
	source $f
done

####################
#### PS1 STUFFS ####
####################

# offload getting ps1 to script
SET_DEFAULT_PS1=0
export MY_PS1=$PS1
function ps1swap {
	SET_DEFAULT_PS1=$((1-$SET_DEFAULT_PS1))
}
function update_ps1 {
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

function find-detached-session {
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

# This is silly
# if [[ -z $NVIM_STARTED ]]; then
# 	export NVIM_STARTED=1
# 	exec nvim "+term" "+startinsert"
# else
# 	alias nvim="echo no;# "
# fi
