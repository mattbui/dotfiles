#!/usr/bin/env bash
set -euo pipefail

# Cycle tmux sessions in MRU order.
#
# Normal tmux `switch-client -n/-p` uses tmux's internal session order. This
# script instead uses per-session @last_access timestamps maintained by
# update-session-access.sh. When cycling starts, it snapshots that MRU order
# into @session_cycle_list and keeps reusing the frozen list while the user
# continues pressing Ctrl-Tab / Ctrl-Shift-Tab within TIMEOUT_SECONDS. This keeps
# the order stable while cycling, like an app switcher.

DIRECTION="${1:-next}"
TIMEOUT_SECONDS="${SESSION_CYCLE_TIMEOUT:-0.6}"
NAME_SEPARATOR=$'\037'

join_words() {
  local output=''
  local item

  for item in "$@"; do
    if [ -n "$output" ]; then
      output="$output $item"
    else
      output="$item"
    fi
  done

  printf '%s' "$output"
}

join_names() {
  local IFS="$NAME_SEPARATOR"
  printf '%s' "$*"
}

format_title_indicator() {
  local count="$1"
  local index="$2"
  local start="$3"
  local visible_count
  local offset
  local item_index
  local output=''
  local name

  # For one/two sessions, keep the left slot simple: just the selected session.
  if [ "$count" -le 2 ]; then
    printf '%s' "${names[$index]}"
    return 0
  fi

  visible_count="$count"
  if [ "$visible_count" -gt 5 ]; then
    visible_count=5
  fi

  for ((offset = 0; offset < visible_count; offset += 1)); do
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

current_id="$(tmux display-message -p '#{session_id}')"

# Existing cycle state. If @session_cycle_active is set and the current session
# is still in the frozen list, this key press continues the same cycle.
active="$(tmux show-option -gqv @session_cycle_active 2>/dev/null || true)"
list="$(tmux show-option -gqv @session_cycle_list 2>/dev/null || true)"
names_blob="$(tmux show-option -gqv @session_cycle_names 2>/dev/null || true)"
index="$(tmux show-option -gqv @session_cycle_index 2>/dev/null || true)"
view_start="$(tmux show-option -gqv @session_cycle_view_start 2>/dev/null || true)"
new_cycle=0
ids=()
names=()

if [ -n "$list" ]; then
  read -r -a ids <<< "$list"
fi
if [ -n "$names_blob" ]; then
  old_ifs="$IFS"
  IFS="$NAME_SEPARATOR"
  read -r -a names <<< "$names_blob"
  IFS="$old_ifs"
fi

list_contains_current=0
for id in "${ids[@]}"; do
  if [ "$id" = "$current_id" ]; then
    list_contains_current=1
    break
  fi
done

if [ "$active" != "1" ] || [ "${#ids[@]}" -eq 0 ] || [ "$list_contains_current" != "1" ]; then
  new_cycle=1
  ids=()
  names=()

  # Seed the current session timestamp only when a fresh cycle is built. This
  # keeps a brand-new server sane without adding a set/show-option round-trip to
  # every repeated Ctrl-Tab press.
  if [ -z "$(tmux show-option -qv -t "$current_id" @last_access 2>/dev/null || true)" ]; then
    tmux set-option -q -t "$current_id" @last_access "$(date +%s)"
  fi

  # Start a new cycle by snapshotting sessions sorted by @last_access
  # descending. Missing timestamps sort oldest, and name is used as a stable
  # tie-breaker. The snapshot is intentionally frozen until the timeout ends.
  while IFS=$'\t' read -r id name; do
    [ -n "$id" ] || continue
    ids+=("$id")
    names+=("$name")
  done < <(
    tmux list-sessions -F '#{session_id}	#{session_name}	#{@last_access}' |
      awk -F '\t' '{ ts=$3; if (ts == "") ts=0; printf "%s\t%s\t%s\n", ts, $2, $1 }' |
      sort -t $'\t' -k1,1nr -k2,2 |
      awk -F '\t' '{ printf "%s\t%s\n", $3, $2 }'
  )

  # Find the current session inside the fresh MRU snapshot.
  index=0
  for ((i = 0; i < ${#ids[@]}; i += 1)); do
    if [ "${ids[$i]}" = "$current_id" ]; then
      index="$i"
      break
    fi
  done
elif [ "${#names[@]}" -ne "${#ids[@]}" ]; then
  # Backward-compatible fallback for an active cycle created before the names
  # sidecar existed, or after a manual option edit.
  names=()
  for id in "${ids[@]}"; do
    names+=("$(tmux display-message -p -t "$id" '#{session_name}' 2>/dev/null || true)")
  done
fi

# Sessions may be closed while the cycle is active. Drop any stale session IDs
# before calculating the next target. Use a single list-sessions call rather
# than one has-session call per candidate.
if [ "$new_cycle" != "1" ]; then
  live_ids="$(tmux list-sessions -F '#{session_id}' 2>/dev/null || true)"
  filtered_ids=()
  filtered_names=()
  for ((i = 0; i < ${#ids[@]}; i += 1)); do
    case $'\n'"$live_ids"$'\n' in
      *$'\n'"${ids[$i]}"$'\n'*)
        filtered_ids+=("${ids[$i]}")
        filtered_names+=("${names[$i]}")
        ;;
    esac
  done
  ids=("${filtered_ids[@]}")
  names=("${filtered_names[@]}")
fi

count="${#ids[@]}"
[ "$count" -gt 1 ] || exit 0

# Re-find the current index in the filtered frozen list. This makes direction
# changes and externally changed sessions behave sanely.
found=0
for ((i = 0; i < count; i += 1)); do
  if [ "${ids[$i]}" = "$current_id" ]; then
    index="$i"
    found=1
    break
  fi
done
[ "$found" = "1" ] || index=0

# The expanded title indicator shows a scrolling viewport over the frozen list.
# A new cycle starts the viewport at the original session. Subsequent keypresses
# only move the selected index until it leaves the viewport, then the viewport
# scrolls just enough to include it.
view_size=5
if [ "$count" -lt "$view_size" ]; then
  view_size="$count"
fi
if [ "$new_cycle" = "1" ] || ! [[ "$view_start" =~ ^[0-9]+$ ]]; then
  view_start="$index"
fi

case "$DIRECTION" in
  next) index=$(( (index + 1) % count )) ;;
  prev|previous) index=$(( (index - 1 + count) % count )) ;;
  *) echo "usage: $0 next|prev" >&2; exit 2 ;;
esac

if [ "$count" -gt "$view_size" ]; then
  view_end=$((view_start + view_size - 1))
  if [ "$index" -lt "$view_start" ]; then
    view_start="$index"
  elif [ "$index" -gt "$view_end" ]; then
    view_start=$((index - view_size + 1))
  fi
fi

# Store all state needed by the next cycle keypress. The token lets each timeout
# know whether it is still the newest one. Use $RANDOM because BSD date does not
# support %N; `date +%s%N` can repeat for every press within the same second on
# macOS.
target_id="${ids[$index]}"
list="$(join_words "${ids[@]}")"
names_blob="$(join_names "${names[@]}")"
title_indicator="$(format_title_indicator "$count" "$index" "$view_start")"
token="$(date +%s)-$$-$RANDOM"

# Switch and refresh in one tmux round-trip. The status line reads the cached
# title directly, so there is no separate update-session-indicators.sh call on
# the hot path.
tmux \
  set-option -gq @session_cycle_active 1 \; \
  set-option -gq @session_cycle_list "$list" \; \
  set-option -gq @session_cycle_names "$names_blob" \; \
  set-option -gq @session_cycle_index "$index" \; \
  set-option -gq @session_cycle_view_start "$view_start" \; \
  set-option -gq @session_cycle_token "$token" \; \
  set-option -gq @session_title_indicator "$title_indicator" \; \
  switch-client -t "$target_id" \; \
  refresh-client -S

# Start/reset the timeout. Every keypress writes a new token; older timers wake
# up, see their token is stale, and exit. The newest timer finalizes the cycle:
# clear frozen state, mark the final session as recently accessed, and redraw.
(
  sleep "$TIMEOUT_SECONDS"
  current_token="$(tmux show-option -gqv @session_cycle_token 2>/dev/null || true)"
  [ "$current_token" = "$token" ] || exit 0

  final_id="$(tmux display-message -p '#{session_id}' 2>/dev/null || true)"
  tmux \
    set-option -gqu @session_cycle_active \; \
    set-option -gqu @session_cycle_list \; \
    set-option -gqu @session_cycle_names \; \
    set-option -gqu @session_cycle_index \; \
    set-option -gqu @session_cycle_view_start \; \
    set-option -gqu @session_cycle_token

  if [ -n "$final_id" ]; then
    tmux set-option -q -t "$final_id" @last_access "$(date +%s)"
  fi
  "${HOME}/.config/tmux/scripts/update-session-indicators.sh" 2>/dev/null || true
  tmux refresh-client -S 2>/dev/null || true
) >/dev/null 2>&1 &
