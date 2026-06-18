#!/usr/bin/env bash
set -euo pipefail

# Do not mutate MRU ordering while scripted Ctrl-Tab cycling is active.
if [ "$(tmux show-option -gqv @session_cycle_active 2>/dev/null || true)" = "1" ]; then
  exit 0
fi

session_id="$(tmux display-message -p '#{session_id}' 2>/dev/null || true)"
[ -n "$session_id" ] || exit 0

tmux set-option -q -t "$session_id" @last_access "$(date +%s)"
"${HOME}/.config/tmux/scripts/update-session-indicators.sh" 2>/dev/null || true
tmux refresh-client -S 2>/dev/null || true
