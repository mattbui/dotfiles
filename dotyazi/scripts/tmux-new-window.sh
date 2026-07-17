#!/bin/sh

if [ -z "${TMUX:-}" ]; then
	printf '%s\n' 'tmux-window: not inside tmux' >&2
	exit 1
fi

target_dir=${1:-$PWD}
if [ ! -d "$target_dir" ]; then
	case $target_dir in
		*/*) target_dir=${target_dir%/*}; [ -n "$target_dir" ] || target_dir=/ ;;
		*) target_dir=$PWD ;;
	esac
fi
[ -d "$target_dir" ] || target_dir=$PWD

tmux new-window -c "$target_dir" || exit 1

if [ "${YAZI_TMUX_POPUP:-}" = "1" ]; then
	ya emit quit
fi
