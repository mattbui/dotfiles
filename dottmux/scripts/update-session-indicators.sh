#!/usr/bin/env bash
set -euo pipefail

# Recompute the tmux user options consumed by the status line:
#   @session_title_indicator - left session title area. Normally the current
#     session name; while cycling, a small viewport over the frozen session list
#     with the selected session marked as *name.
#   @session_cycle_indicator - compact right-side hint showing where
#     Ctrl-Tab will go: "next →".
#
# The status line reads these options directly instead of running #(...), so
# status rendering stays cheap. Hooks and switch-session-mru.sh call this script
# whenever the underlying session state changes.

format_cycle_indicator() {
  local next="$1"

  if [ -z "$next" ]; then
    printf ''
  else
    printf '%s →' "$next"
  fi
}

format_session_list() {
  local list="$1"
  local index="$2"
  local start="$3"
  local count
  local visible_count
  local offset
  local item_index
  local id
  local name
  local output=''

  count=$(wc -w <<< "$list" | tr -d ' ')
  [ "$count" -gt 0 ] || return 0

  # Show at most five sessions in the expanded title indicator. The viewport
  # start is managed by switch-session-mru.sh so the selection moves first, and
  # the viewport scrolls only when the selection leaves the visible range.
  visible_count=$count
  if [ "$visible_count" -gt 5 ]; then
    visible_count=5
  fi

  for offset in $(seq 0 $((visible_count - 1))); do
    item_index=$(( (start + offset + count) % count ))
    id="$(awk -v n=$((item_index + 1)) '{ print $n }' <<< "$list")"
    name="$(tmux display-message -p -t "$id" '#{session_name}' 2>/dev/null || true)"
    [ -n "$name" ] || continue

    if [ -n "$output" ]; then
      output="$output | "
    fi
    if [ "$item_index" -eq "$index" ]; then
      output="${output}*${name}"
    else
      output="${output}${name}"
    fi
  done

  printf '%s' "$output"
}

mru_list() {
  # Return session IDs ordered by last access descending. Sessions without a
  # timestamp are treated as oldest; name is a stable tie-breaker.
  tmux list-sessions -F '#{session_id}	#{session_name}	#{@last_access}' 2>/dev/null |
    awk -F '\t' '{ ts=$3; if (ts == "") ts=0; printf "%s\t%s\t%s\n", ts, $2, $1 }' |
    sort -t $'\t' -k1,1nr -k2,2 |
    awk -F '\t' '{ print $3 }' |
    tr '\n' ' ' |
    sed 's/[[:space:]]*$//'
}

find_index() {
  local list="$1"
  local current_id="$2"
  local i=0

  for id in $list; do
    if [ "$id" = "$current_id" ]; then
      printf '%s' "$i"
      return 0
    fi
    i=$((i + 1))
  done

  return 1
}

cycle_indicator=''
title_indicator=''
active="$(tmux show-option -gqv @session_cycle_active 2>/dev/null || true)"
current_id="$(tmux display-message -p '#{session_id}' 2>/dev/null || true)"
current_name="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"

# Default title slot is just the current session name.
title_indicator="$current_name"

if [ "$active" = "1" ]; then
  # During an active cycle, use the frozen list and viewport maintained by
  # switch-session-mru.sh. This avoids the list jumping around while repeated
  # Ctrl-Tab presses are still in progress.
  list="$(tmux show-option -gqv @session_cycle_list 2>/dev/null || true)"
  index="$(tmux show-option -gqv @session_cycle_index 2>/dev/null || true)"
  view_start="$(tmux show-option -gqv @session_cycle_view_start 2>/dev/null || true)"
  next="$(tmux show-option -gqv @session_cycle_next_name 2>/dev/null || true)"

  cycle_indicator="$(format_cycle_indicator "$next")"
  count=$(wc -w <<< "$list" | tr -d ' ')
  if [ "$count" -gt 2 ] && [[ "$index" =~ ^[0-9]+$ ]] && [[ "$view_start" =~ ^[0-9]+$ ]]; then
    title_indicator="$(format_session_list "$list" "$index" "$view_start")"
  fi
elif [ -n "$current_id" ]; then
  # Outside cycling, compute the compact next-session hint from live MRU state.
  list="$(mru_list)"
  count=$(wc -w <<< "$list" | tr -d ' ')
  if [ "$count" -gt 1 ] && index="$(find_index "$list" "$current_id")"; then
    next_index=$(( (index + 1) % count ))
    next_id="$(awk -v n=$((next_index + 1)) '{ print $n }' <<< "$list")"
    next_name="$(tmux display-message -p -t "$next_id" '#{session_name}' 2>/dev/null || true)"
    cycle_indicator="$(format_cycle_indicator "$next_name")"
  fi
fi

# Store plain text only; tmux-status.conf applies colors/layout.
tmux set-option -gq @session_title_indicator "$title_indicator"
tmux set-option -gq @session_cycle_indicator "$cycle_indicator"
