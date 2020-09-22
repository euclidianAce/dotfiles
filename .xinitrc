#!/usr/bin/env bash
xrdb -merge ~/.Xresources
setxkbmap us -variant colemak
xmodmap $DOTFILE_DIR/remaps.Xmodmap
exec sakura & awesome
# exec ~/dev/mywm/a.out > log.txt
#exec urxvtc & ~/Applications/firefox/firefox & ~/Applications/mywm/run
