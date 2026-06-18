#!/usr/bin/env bash
set -euo pipefail

DIRECTION="${1:-next}"
TIMEOUT_SECONDS="${SESSION_CYCLE_TIMEOUT:-0.6}"

current_id="$(tmux display-message -p '#{session_id}')"
current_name="$(tmux display-message -p '#{session_name}')"
now="$(date +%s)"

# Ensure current session has an access timestamp before building an initial list.
if [ -z "$(tmux show-option -qv -t "$current_id" @last_access 2>/dev/null || true)" ]; then
  tmux set-option -q -t "$current_id" @last_access "$now"
fi

active="$(tmux show-option -gqv @session_cycle_active 2>/dev/null || true)"
list="$(tmux show-option -gqv @session_cycle_list 2>/dev/null || true)"
index="$(tmux show-option -gqv @session_cycle_index 2>/dev/null || true)"

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
  # Snapshot MRU order. Missing timestamps sort oldest. Tie-break by name for stability.
  list="$({
    tmux list-sessions -F '#{session_id}	#{session_name}	#{@last_access}' |
      awk -F '\t' '{ ts=$3; if (ts == "") ts=0; printf "%s\t%s\t%s\n", ts, $2, $1 }' |
      sort -t $'\t' -k1,1nr -k2,2 |
      awk -F '\t' '{ print $3 }'
  } | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
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

# Filter out sessions that disappeared while cycling.
filtered=""
for id in $list; do
  if session_exists "$id"; then
    filtered="$filtered $id"
  fi
done
list="${filtered# }"

count=$(wc -w <<< "$list" | tr -d ' ')
[ "$count" -gt 1 ] || exit 0

# Re-find current index in the filtered frozen list, so manual direction reversals are sane.
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

case "$DIRECTION" in
  next) index=$(( (index + 1) % count )) ;;
  prev|previous) index=$(( (index - 1 + count) % count )) ;;
  *) echo "usage: $0 next|prev" >&2; exit 2 ;;
esac

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
tmux set-option -gq @session_cycle_token "$token"
tmux set-option -gq @session_cycle_target "$target_id"
tmux set-option -gq @session_cycle_target_name "$target_name"
tmux set-option -gq @session_cycle_prev_name "$prev_name"
tmux set-option -gq @session_cycle_next_name "$next_name"

tmux switch-client -t "$target_id"
"${HOME}/.config/tmux/scripts/update-session-indicators.sh" 2>/dev/null || true
tmux refresh-client -S 2>/dev/null || true

# Finalize only if no newer cycle key has replaced our token.
(
  sleep "$TIMEOUT_SECONDS"
  current_token="$(tmux show-option -gqv @session_cycle_token 2>/dev/null || true)"
  [ "$current_token" = "$token" ] || exit 0

  final_id="$(tmux display-message -p '#{session_id}' 2>/dev/null || true)"
  tmux set-option -gqu @session_cycle_active
  tmux set-option -gqu @session_cycle_list
  tmux set-option -gqu @session_cycle_index
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
