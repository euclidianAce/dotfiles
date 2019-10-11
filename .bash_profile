#!/usr/bin/bash

# if running bash
if [ -n "$BASH_VERSION" ]; then
	# include .bashrc if it exists
	if [ -f "$HOME/.bashrc" ]; then
		. "$HOME/.bashrc"
	fi
fi

# start X if on TTY 1
if [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
	exec startx
fi

# custom commands
export PATH=$PATH:"$HOME/bin/"

