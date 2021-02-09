#!/usr/bin/env bash
xrdb -merge ~/.Xresources
setxkbmap us -variant colemak
xmodmap $DOTFILE_DIR/remaps.Xmodmap
# exec awesome
# exec dwm
# exec ~/dev/mywm/run > log.txt
