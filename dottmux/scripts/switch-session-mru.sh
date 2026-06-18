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
TIMEOUT_SECONDS="${SESSION_CYCLE_TIMEOUT:-1}"

current_id="$(tmux display-message -p '#{session_id}')"
now="$(date +%s)"

# Seed the current session timestamp so a brand-new tmux server has at least one
# meaningful MRU entry before the first cycle list is built.
if [ -z "$(tmux show-option -qv -t "$current_id" @last_access 2>/dev/null || true)" ]; then
  tmux set-option -q -t "$current_id" @last_access "$now"
fi

# Existing cycle state. If @session_cycle_active is set and the current session
# is still in the frozen list, this key press continues the same cycle.
active="$(tmux show-option -gqv @session_cycle_active 2>/dev/null || true)"
list="$(tmux show-option -gqv @session_cycle_list 2>/dev/null || true)"
index="$(tmux show-option -gqv @session_cycle_index 2>/dev/null || true)"
view_start="$(tmux show-option -gqv @session_cycle_view_start 2>/dev/null || true)"
new_cycle=0

session_exists() {
  tmux has-session -t "$1" 2>/dev/null
}

list_contains_current=0
for id in $list; do
  if [ "$id" = "$current_id" ]; then
    list_contains_current=1
    break
  fi
done

if [ "$active" != "1" ] || [ -z "$list" ] || [ "$list_contains_current" != "1" ]; then
  new_cycle=1

  # Start a new cycle by snapshotting sessions sorted by @last_access
  # descending. Missing timestamps sort oldest, and name is used as a stable
  # tie-breaker. The snapshot is intentionally frozen until the timeout ends.
  list="$({
    tmux list-sessions -F '#{session_id}	#{session_name}	#{@last_access}' |
      awk -F '\t' '{ ts=$3; if (ts == "") ts=0; printf "%s\t%s\t%s\n", ts, $2, $1 }' |
      sort -t $'\t' -k1,1nr -k2,2 |
      awk -F '\t' '{ print $3 }'
  } | tr '\n' ' ' | sed 's/[[:space:]]*$//')"

  # Find the current session inside the fresh MRU snapshot.
  index=0
  i=0
  for id in $list; do
    if [ "$id" = "$current_id" ]; then
      index="$i"
      break
    fi
    i=$((i + 1))
  done
fi

# Sessions may be closed while the cycle is active. Drop any stale session IDs
# before calculating the next target.
filtered=""
for id in $list; do
  if session_exists "$id"; then
    filtered="$filtered $id"
  fi
done
list="${filtered# }"

count=$(wc -w <<< "$list" | tr -d ' ')
[ "$count" -gt 1 ] || exit 0

# Re-find the current index in the filtered frozen list. This makes direction
# changes and externally changed sessions behave sanely.
i=0
found=0
for id in $list; do
  if [ "$id" = "$current_id" ]; then
    index="$i"
    found=1
    break
  fi
  i=$((i + 1))
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

# Store all state needed by update-session-indicators.sh and by the next cycle
# keypress. The token lets each timeout know whether it is still the newest one.
target_id="$(awk -v n=$((index + 1)) '{ print $n }' <<< "$list")"
target_name="$(tmux display-message -p -t "$target_id" '#{session_name}')"
prev_index=$(( (index - 1 + count) % count ))
next_index=$(( (index + 1) % count ))
prev_id="$(awk -v n=$((prev_index + 1)) '{ print $n }' <<< "$list")"
next_id="$(awk -v n=$((next_index + 1)) '{ print $n }' <<< "$list")"
prev_name="$(tmux display-message -p -t "$prev_id" '#{session_name}')"
next_name="$(tmux display-message -p -t "$next_id" '#{session_name}')"
token="$(date +%s%N)"

tmux set-option -gq @session_cycle_active 1
tmux set-option -gq @session_cycle_list "$list"
tmux set-option -gq @session_cycle_index "$index"
tmux set-option -gq @session_cycle_view_start "$view_start"
tmux set-option -gq @session_cycle_token "$token"
tmux set-option -gq @session_cycle_target "$target_id"
tmux set-option -gq @session_cycle_target_name "$target_name"
tmux set-option -gq @session_cycle_prev_name "$prev_name"
tmux set-option -gq @session_cycle_next_name "$next_name"

# Switch, then refresh indicators immediately so status reflects the new target
# without waiting for status-interval.
tmux switch-client -t "$target_id"
"${HOME}/.config/tmux/scripts/update-session-indicators.sh" 2>/dev/null || true
tmux refresh-client -S 2>/dev/null || true

# Start/reset the timeout. Every keypress writes a new token; older timers wake
# up, see their token is stale, and exit. The newest timer finalizes the cycle:
# clear frozen state, mark the final session as recently accessed, and redraw.
(
  sleep "$TIMEOUT_SECONDS"
  current_token="$(tmux show-option -gqv @session_cycle_token 2>/dev/null || true)"
  [ "$current_token" = "$token" ] || exit 0

  final_id="$(tmux display-message -p '#{session_id}' 2>/dev/null || true)"
  tmux set-option -gqu @session_cycle_active
  tmux set-option -gqu @session_cycle_list
  tmux set-option -gqu @session_cycle_index
  tmux set-option -gqu @session_cycle_view_start
  tmux set-option -gqu @session_cycle_token
  tmux set-option -gqu @session_cycle_target
  tmux set-option -gqu @session_cycle_target_name
  tmux set-option -gqu @session_cycle_prev_name
  tmux set-option -gqu @session_cycle_next_name

  if [ -n "$final_id" ]; then
    tmux set-option -q -t "$final_id" @last_access "$(date +%s)"
  fi
  "${HOME}/.config/tmux/scripts/update-session-indicators.sh" 2>/dev/null || true
  tmux refresh-client -S 2>/dev/null || true
) >/dev/null 2>&1 &
