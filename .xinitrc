#!/usr/bin/env bash
xrdb -merge ~/.Xresources
urxvtd -q -o -f
exec awesome
