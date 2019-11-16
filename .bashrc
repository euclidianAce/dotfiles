
    ######                  #
    ##   ##                 #
    ##   ##  ####    ###### # ###   # ####   #####
    ######       #  #       ##   #  ##    # #     #
    ##   ##  ####    #####  #     # #       #
##  ##   ## #   ##        # #     # #       #     #
##  ######   ###  # ######  #     # #        #####  


# vi mode: allows vi style commands within bash
set -o vi

shopt -s autocd # Automatically does a cd when you type a directory
shopt -s checkwinsize # resize window automatically after each command

#################
#### ALIASES ####
#################

# default options
alias ls="ls -hN --file-type --color=auto --group-directories-first"
alias la="ls -AhN --file-type --color=auto --group-directories-first"
alias grep="grep --color=auto"

# always ask before emerging and do it quietly
alias emerge="sudo emerge --ask --quiet"
alias emergev="sudo emerge --ask"
alias emergef="sudo emerge --ask --fetchonly --quiet"
alias etc-update="sudo etc-update"

# power stuffs 
alias sdn="sudo shutdown -h now"
alias rb="sudo reboot"

# config file editing and reloading
alias refresh="source ~/.bashrc" #reload bashrc
alias vbrc="nvim ~/.bashrc && source ~/.bashrc"
alias vxr="nvim ~/.Xresources && xrdb ~/.Xresources"
alias vvrc="nvim ~/.vimrc"
alias vps1="nvim ~/.config/.ps1Getter.lua"

# actual "aliases"
alias v="nvim"


##########################
#### ENVIRONMENT VARS ####
##########################

# set vim as the default editor
export EDITOR=vim

# custom scripts
export PATH="$PATH:~/bin"

# offload getting ps1 to lua script
function update_ps1 { 
	PS1=$( lua $HOME/.config/.ps1Getter.lua 2> /dev/null || echo "(Error getting PS1) $ ") 
}
update_ps1
PROMPT_COMMAND=update_ps1
