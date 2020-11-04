#!/usr/bin/env bash
xrdb -merge ~/.Xresources
setxkbmap us -variant colemak
xmodmap $DOTFILE_DIR/remaps.Xmodmap
exec st & awesome
# exec ~/dev/mywm/a.out > log.txt
