#!/bin/sh
tmux_pane=$1

printf 'Title (empty to skip): '
IFS= read -r title || exit 0
[ -n "$title" ] || exit 0

if [ "${#title}" -gt 15 ]; then
  title="$(printf '%s' "$title" | cut -c 1-12)..."
fi

tmux select-pane -t "$tmux_pane" -T "$title" 2>/dev/null || true
