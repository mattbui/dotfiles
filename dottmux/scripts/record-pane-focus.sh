#!/bin/sh

pane_id="$1"
[ -n "$pane_id" ] || exit 0

state_dir="${TMPDIR:-/tmp}/tmux-pane-focus-${USER:-user}"
state_file="${state_dir}/history"

mkdir -p "$state_dir" || exit 0

current_panes="$(tmux list-panes -a -F '#{pane_id}')"

awk -v pane_id="$pane_id" -v current_panes="$current_panes" '
    BEGIN {
        split(current_panes, panes, "\n")
        for (i in panes) {
            alive[panes[i]] = 1
        }
    }
    $1 != pane_id && alive[$1]
' "$state_file" 2>/dev/null > "${state_file}.tmp"
printf '%s %s\n' "$pane_id" "$(date +%s)" >> "${state_file}.tmp"
mv "${state_file}.tmp" "$state_file"
