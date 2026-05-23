#!/bin/sh
tmux_pane=$1

printf 'Title (empty to skip): '
IFS= read -r title || exit 0
[ -n "$title" ] || exit 0

if [ "${#title}" -gt 100 ]; then
  title="$(printf '%s' "$title" | cut -c 1-98).."
fi

tmux set-option -p -t "$tmux_pane" @codex_session_active 1 2>/dev/null || true
tmux set-option -p -t "$tmux_pane" @codex_session_name "$title" 2>/dev/null || true
