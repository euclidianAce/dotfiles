source ~/.bashrc
export PATH="$PATH:~/bin"

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then exec startx; fi
