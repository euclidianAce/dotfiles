#!/bin/sh

# installs dotfiles into ~ directory from git repo
# i.e. makes a hard link to the files in .config

# files:
# .bashrc
# .vimrc
# .xinitrc
# .gitconfig
# .Xresources

(ln -f ~/.config/.bashrc ~/.bashrc && echo .bashrc hard linked) || echo .bashrc hard link failed
(ln -f ~/.config/.vimrc ~/.vimrc && echo .vimrc hard linked) || echo .vimrc hard link failed
(ln -f ~/.config/.xinitrc ~/.xinitrc && echo .xinitrc hard linked) || echo .xinitrc hard link failed
(ln -f ~/.config/.Xresources ~/.Xresources && echo .Xresources hard linked) || echo .Xresources hard link failed
(ln -f ~/.config/.gitconfig ~/.gitconfig && echo .gitconfig hard linked) || echo .gitconfig hard link failed
(ln -sf ~/.config/urxvt ~/.urxvt && echo .urxvt directory symbolically linked) || echo .urxvt symbolic link failed
