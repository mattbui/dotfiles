#!/bin/sh

if [ -z "${TMUX:-}" ]; then
	printf '%s\n' 'tmux-session: not inside tmux' >&2
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

base=${target_dir##*/}
[ -n "$base" ] || base=root
base=$(printf '%s' "$base" | tr ':' '_')

session_name=$base
index=1
while tmux has-session -t "=$session_name" 2>/dev/null; do
	session_name="${base}(${index})"
	index=$((index + 1))
done

if tmux new-session -d -s "$session_name" -c "$target_dir" && tmux switch-client -t "=$session_name"; then
	if [ "${YAZI_TMUX_POPUP:-}" = "1" ]; then
		ya emit quit
	fi
else
	printf 'failed to create tmux session: %s\n' "$session_name" >&2
	exit 1
fi
