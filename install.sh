#!/bin/sh

# installs dotfiles into ~ directory from git repo
# i.e. makes a hard link to the files in .config

# files:
# .bashrc
# .vimrc
# .xinitrc
# .gitconfig
# .Xresources

(ln -sf ~/.config/.bashrc ~/.bashrc && echo .bashrc symbolically linked) || echo .bashrc hard link failed
(ln -sf ~/.config/.vimrc ~/.vim/vimrc && echo .vimrc symbolically linked) || echo .vimrc hard link failed
(ln -sf ~/.config/.xinitrc ~/.xinitrc && echo .xinitrc symbolically linked) || echo .xinitrc hard link failed
(ln -sf ~/.config/.Xresources ~/.Xresources && echo .Xresources symbolically linked) || echo .Xresources hard link failed
(ln -sf ~/.config/.gitconfig ~/.gitconfig && echo .gitconfig symbolically linked) || echo .gitconfig hard link failed
(ln -sf ~/.config/urxvt ~/.urxvt && echo .urxvt directory symbolically linked) || echo .urxvt symbolic link failed
