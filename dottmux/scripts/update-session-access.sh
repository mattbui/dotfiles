#!/usr/bin/env bash
set -euo pipefail

# Hook target for tmux client-session-changed.
#
# For normal session switches (choose-tree, switch-client -t, etc.), mark the
# newly focused session as recently accessed. switch-session-mru.sh temporarily
# sets @session_cycle_active while Ctrl-Tab cycling, so intermediate sessions do
# not reshuffle MRU order. The final selected session is marked when the cycle
# timeout expires.

if [ "$(tmux show-option -gqv @session_cycle_active 2>/dev/null || true)" = "1" ]; then
  exit 0
fi

session_id="$(tmux display-message -p '#{session_id}' 2>/dev/null || true)"
[ -n "$session_id" ] || exit 0

tmux set-option -q -t "$session_id" @last_access "$(date +%s)"
"${HOME}/.config/tmux/scripts/update-session-indicators.sh" 2>/dev/null || true
tmux refresh-client -S 2>/dev/null || true
