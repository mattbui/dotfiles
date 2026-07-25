#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${TMUX:-}" || -z "${TMUX_SOCKET:-}" ]]; then
  exec tmux "$@"
fi

exec tmux -L "$TMUX_SOCKET" "$@"
