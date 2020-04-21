#!/usr/bin/env bash
xset +fp /usr/share/fonts/terminus
xrdb -merge ~/.Xresources
urxvtd -q -o -f
picom -b
exec awesome
