#!/usr/bin/env bash
set -euo pipefail

# Recompute the tmux user option consumed by the status line:
#   @session_title_indicator - left session title area. Normally the current
#     session name; while cycling, a small viewport over the frozen session list
#     with the selected session marked as *name.
#
# The status line reads this option directly instead of running #(...), so
# status rendering stays cheap. Hooks and switch-session-mru.sh call this script
# whenever the underlying session state changes.

NAME_SEPARATOR=$'\037'

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

format_session_names() {
  local names_blob="$1"
  local index="$2"
  local start="$3"
  local count="$4"
  local names=()
  local old_ifs
  local visible_count
  local offset
  local item_index
  local name
  local output=''

  old_ifs="$IFS"
  IFS="$NAME_SEPARATOR"
  read -r -a names <<< "$names_blob"
  IFS="$old_ifs"

  [ "${#names[@]}" -eq "$count" ] || return 1

  visible_count=$count
  if [ "$visible_count" -gt 5 ]; then
    visible_count=5
  fi

  for offset in $(seq 0 $((visible_count - 1))); do
    item_index=$(( (start + offset + count) % count ))
    name="${names[$item_index]}"
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

title_indicator="$(tmux display-message -p '#{session_name}' 2>/dev/null || true)"
active="$(tmux show-option -gqv @session_cycle_active 2>/dev/null || true)"

if [ "$active" = "1" ]; then
  # During an active cycle, use the frozen list and viewport maintained by
  # switch-session-mru.sh. This avoids the list jumping around while repeated
  # Ctrl-Tab presses are still in progress.
  list="$(tmux show-option -gqv @session_cycle_list 2>/dev/null || true)"
  names_blob="$(tmux show-option -gqv @session_cycle_names 2>/dev/null || true)"
  index="$(tmux show-option -gqv @session_cycle_index 2>/dev/null || true)"
  view_start="$(tmux show-option -gqv @session_cycle_view_start 2>/dev/null || true)"

  count=$(wc -w <<< "$list" | tr -d ' ')
  if [ "$count" -gt 2 ] && [[ "$index" =~ ^[0-9]+$ ]] && [[ "$view_start" =~ ^[0-9]+$ ]]; then
    title_indicator="$(format_session_names "$names_blob" "$index" "$view_start" "$count" || format_session_list "$list" "$index" "$view_start")"
  fi
fi

# Store plain text only; tmux-status.conf applies colors/layout.
tmux set-option -gq @session_title_indicator "$title_indicator"
