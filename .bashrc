
    ######                  #
    ##   ##                 #
    ##   ##  ####    ###### # ###   # ####   #####
    ######       #  #       ##   #  ##    # #     #
    ##   ##  ####    #####  #     # #       #
##  ##   ## #   ##        # #     # #       #     #
##  ######   ###  # ######  #     # #        #####  


# vi mode: allows vi style commands within bash
set -o vi

shopt -s autocd		# Automatically does a cd when you type a directory
shopt -s checkwinsize 	# resize window automatically after each command

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

# set vim as the default editor
export EDITOR=vim

# Additions to PATH
eval $(luarocks path --bin)
export LUA_PATH+=";$HOME/lualibs/?.lua;$HOME/lualibs/?/init.lua"
export LUA_CPATH+=";$HOME/lualibs/?.so;$HOME/lualibs/?/?.so"
export PATH+=":$HOME/bin"

#################
#### ALIASES ####
#################

for f in $HOME/.config/bash_aliases/*; do
	source $f
done

function mkcd {
	mkdir $1; cd $1
}

##########################
####    PS1 STUFFS    ####
##########################

# offload getting ps1 to lua script
DEFAULT_PS1=$PS1
function update_ps1 { 
	PS1=$(lua $HOME/.config/ps1Getter.lua 2> $HOME/.config/ps1ErrLog.log)
	if [ "$PS1" = "" ]; then
		PS1=$DEFAULT_PS1
	fi
}
update_ps1
PROMPT_COMMAND=update_ps1
