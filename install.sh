#!/bin/sh

# installs dotfiles into ~ directory from git repo
# i.e. makes a hard link to the files in .config

# files:
# .bashrc
# .vimrc
# .xinitrc
# .Xresources

(ln -f ~/.config/.bashrc ~/.bashrc && echo .bashrc copied) || echo .bashrc copy failed
(ln -f ~/.config/.vimrc ~/.vimrc && echo .vimrc copied) || echo .vimrc copy failed
(ln -f ~/.config/.xinitrc ~/.xinitrc && echo .xinitrc copied) || echo .xinitrc copy failed
(ln -f ~/.config/.Xresources ~/.Xresources && echo .Xresources copied) || echo .Xresources copy failed

