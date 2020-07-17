
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
export EDITOR=nvim
export MANPAGER="nvim +Man!"

# Additions to PATH
export PATH+=":/usr/local/openresty/bin:$HOME/ngrok:$HOME/bin:$HOME/dev/tl"
eval $(luarocks path --bin)

#################
#### ALIASES ####
#################

for f in $DOTFILE_DIR/bash_aliases/*; do
	source $f
done

##########################
####    PS1 STUFFS    ####
##########################

# offload getting ps1 to lua script
SET_DEFAULT_PS1=0
DEFAULT_PS1=$PS1
function ps1swap {
	SET_DEFAULT_PS1=$((1-$SET_DEFAULT_PS1))
}
function update_ps1 { 
	if (( $SET_DEFAULT_PS1 == 1 )); then
		PS1=$DEFAULT_PS1
		return 0
	fi
	PS1=$(luajit $HOME/.config/ps1Getter.lua 2> $HOME/.config/ps1ErrLog.log)
	if [ "$PS1" = "" ]; then
		PS1=$DEFAULT_PS1
	fi
}
update_ps1
PROMPT_COMMAND=update_ps1

# This is silly
# if [[ -z $NVIM_STARTED ]]; then
# 	export NVIM_STARTED=1
# 	exec nvim "+term"
# fi
