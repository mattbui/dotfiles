#!/bin/sh

if [ "$#" -gt 0 ]; then
  session_name=$1
else
  printf 'Session name (empty to skip): '
  IFS= read -r session_name || exit 0
fi
[ -n "$session_name" ] || exit 0

case "$session_name" in
  *:*)
    printf 'Session name cannot contain ":"\n'
    sleep 2
    exit 1
    ;;
esac

current_path=${2:-${PWD:-$HOME}}
[ -d "$current_path" ] || current_path=$HOME

if tmux has-session -t "=$session_name" 2>/dev/null; then
  printf 'Session already exists: %s\n' "$session_name"
  sleep 2
  exit 1
fi

if tmux new-session -d -s "$session_name" -c "$current_path"; then
  tmux switch-client -t "=$session_name"
else
  printf 'Failed to create session: %s\n' "$session_name"
  sleep 2
  exit 1
fi
