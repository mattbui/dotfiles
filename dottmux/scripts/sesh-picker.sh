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

result="$({
  sesh list --icons --hide-duplicates --hide-attached |
    fzf-tmux -p 70%,50% \
      --ansi \
      --expect=ctrl-t \
      --height=100% \
      --reverse \
      --border 'sharp' \
      --border-label ' sesh ' \
      --header '↵ open session  ^p sesh  ^f directories  ^t new window' \
      --prompt '📺 ' \
      --bind 'ctrl-p:change-prompt(📺 )+reload(sesh list --icons --hide-duplicates --hide-attached)' \
      --bind 'ctrl-f:change-prompt(🔎 )+reload(fd -H -d 2 -t d -E .Trash . ~ | sed "s/^/ /")' \
      --preview-window 'right:55%,border-sharp' \
      --preview 'sesh preview {}'
})" || exit 0

[ -n "$result" ] || exit 0

if [[ "$result" == ctrl-t$'\n'* ]]; then
  selection="${result#*$'\n'}"
  if [[ "$selection" != " "* ]]; then
    tmux display-message "Select a directory entry to create a window"
    exit 0
  fi
  sesh window "${selection# }"
  exit 0
fi

sesh connect "$result"
