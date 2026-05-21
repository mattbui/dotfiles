#!/bin/sh

current_session="$(tmux display-message -p '#{session_id}')"
existing_picker="$(tmux list-panes -a -F '#{session_id} #{pane_id} #{pane_title}' |
    awk -v session="$current_session" '$1 == session && $3 == "__choose_tree_split__" { print $2; exit }')"

if [ -n "$existing_picker" ]; then
    tmux kill-pane -t "$existing_picker"
    exit
fi

tmux split-window -h -b -f -p 20 "${HOME}/.config/tmux/scripts/choose-tree-pane.sh"
