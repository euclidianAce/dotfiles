
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
source /etc/profile
export PATH="$PATH:~/bin"
eval $(luarocks path --bin)
LUA_PATH+=";$HOME/lualibs/?.lua;$HOME/lualibs/?/init.lua"
LUA_CPATH+=";$HOME/lualibs/?.so;$HOME/lualibs/?/?.so"
PATH+=":~/VSCode-linux-x64/bin"

#################
#### ALIASES ####
#################

for f in $HOME/.config/bash_aliases/*; do
	source $f
done


##########################
####    PS1 STUFFS    ####
##########################

# offload getting ps1 to lua script
DEFAULT_PS1=$PS1
function update_ps1 { 
	PS1=$(lua $HOME/.config/ps1Getter.lua 2> /dev/null)
	if [ "$PS1" = "" ]; then
		PS1=$DEFAULT_PS1
	fi
}
update_ps1
PROMPT_COMMAND=update_ps1
