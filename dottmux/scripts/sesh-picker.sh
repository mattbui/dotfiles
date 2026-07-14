#!/usr/bin/env bash
set -euo pipefail

if ! command -v sesh >/dev/null 2>&1; then
  tmux display-message "sesh is not installed"
  exit 1
fi

if ! command -v fzf-tmux >/dev/null 2>&1; then
  tmux display-message "fzf-tmux is not installed"
  exit 1
fi

selection="$({
  sesh list --icons --hide-duplicates --hide-attached |
    fzf-tmux -p 70%,50% \
      --ansi \
      --height=100% \
      --reverse \
      --border-label ' sesh ' \
      --prompt '⚡' \
      --preview-window 'right:55%' \
      --preview 'sesh preview {}'
})" || exit 0

[ -n "$selection" ] || exit 0
sesh connect "$selection"
