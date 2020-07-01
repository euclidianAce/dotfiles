
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

# set nvim as the default editor
export EDITOR=nvim

# Additions to PATH
export PATH+=":/usr/local/openresty/bin:$HOME/ngrok:$HOME/bin:$HOME/dev/tl"
export LUA_PATH_5_3+=";$HOME/lualibs/?.lua;$HOME/lualibs/?/init.lua"
export LUA_CPATH_5_3+=";$HOME/lualibs/?.so;$HOME/lualibs/?/?.so;./?.so"
eval $(luarocks path --bin)
export LUA_PATH_5_4+=";$HOME/lualibs/?.lua;$HOME/lualibs/?/init.lua"
export LUA_CPATH_5_4+=";$HOME/lualibs/?.so;$HOME/lualibs/?/?.so;./?.so"

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
