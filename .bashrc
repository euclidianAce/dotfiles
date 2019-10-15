# bashrc from scratch 
shopt -s autocd # Automatically does a cd when you type a directory
shopt -s checkwinsize # resize window automatically after each command

# aliases
alias ls="ls -hN --color=auto --group-directories-first"
alias la="ls -A --color=auto --group-directories-first"
alias v="vim"
alias refresh="source ~/.bashrc" #reload bashrc
alias grep="grep --color=auto"

# custom scripts
export PATH="$PATH:~/bin"

# set the bash prompt
WHITE="\[\e[37m\]"
GRAY="\[\e[94m\]"
NORM="\[\e[0m\]"
BOLD="\[\e[1m\]"
DBLUE="\[\e[34m\]"
LB="$WHITE[$NORM"
M="$WHITE|$NORM"
RB="$WHITE]$NORM"

PS1=""
PS1+=$LB
PS1+="$GRAY\@$NORM"
PS1+=$M
PS1+="\u"
PS1+=$M
PS1+="$DBLUE$BLUE\w$NORM"
PS1+=$RB
PS1+="$ "

# set vim as the default editor
export EDITOR=vim
