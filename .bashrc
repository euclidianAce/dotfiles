# bashrc from scratch 

# vi mode: allows vi style commands within bash
set -o vi

shopt -s autocd # Automatically does a cd when you type a directory
shopt -s checkwinsize # resize window automatically after each command

# aliases
alias ls="ls -hN --file-type --color=auto --group-directories-first"
alias la="ls -AhN --file-type --color=auto --group-directories-first"
alias v="vim"
alias refresh="source ~/.bashrc" #reload bashrc
alias grep="grep --color=auto"

#always ask before emerging and do it quietly
alias emerge="emerge --ask --quiet"
alias emergev="emerge --ask"

# custom scripts
export PATH="$PATH:~/bin"

# set vim as the default editor
export EDITOR=vim


# offload getting ps1 to lua script
PS1=""
function update_ps1 {
	PS1=$( lua $HOME/.ps1Getter.lua 2> /dev/null )
}
update_ps1
PROMPT_COMMAND=update_ps1
