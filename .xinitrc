#!/usr/bin/env bash
xrdb -merge ~/.Xresources
setxkbmap us -variant colemak
exec sakura & awesome
#exec urxvtc & ~/Applications/firefox/firefox & ~/Applications/mywm/run
