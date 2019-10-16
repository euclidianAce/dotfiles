#!/usr/bin/env bash
dbus-update-activation-environment DISPLAY XAUTHORITY
exec i3
# set background
exec ./.fehbg
