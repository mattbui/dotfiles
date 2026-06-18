#!/usr/bin/env bash
set -euo pipefail

format_cycle_indicator() {
  local prev="$1"
  local next="$2"

  if [ -z "$prev$next" ]; then
    printf ''
  elif [ "$prev" = "$next" ]; then
    printf '%s →' "$next"
  else
    printf '← %s | %s →' "$prev" "$next"
  fi
}

format_session_list() {
  local list="$1"
  local index="$2"
  local count
  local visible_count
  local half
  local start
  local offset
  local item_index
  local id
  local name
  local output=''

  count=$(wc -w <<< "$list" | tr -d ' ')
  [ "$count" -gt 0 ] || return 0

  visible_count=$count
  if [ "$visible_count" -gt 5 ]; then
    visible_count=5
  fi
  half=$((visible_count / 2))
  start=$((index - half))

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

title_indicator="$current_name"

if [ "$active" = "1" ]; then
  list="$(tmux show-option -gqv @session_cycle_list 2>/dev/null || true)"
  index="$(tmux show-option -gqv @session_cycle_index 2>/dev/null || true)"
  prev="$(tmux show-option -gqv @session_cycle_prev_name 2>/dev/null || true)"
  next="$(tmux show-option -gqv @session_cycle_next_name 2>/dev/null || true)"

  cycle_indicator="$(format_cycle_indicator "$prev" "$next")"
  if [ -n "$list" ] && [[ "$index" =~ ^[0-9]+$ ]]; then
    title_indicator="$(format_session_list "$list" "$index")"
  fi
elif [ -n "$current_id" ]; then
  list="$(mru_list)"
  count=$(wc -w <<< "$list" | tr -d ' ')
  if [ "$count" -gt 1 ] && index="$(find_index "$list" "$current_id")"; then
    prev_index=$(( (index - 1 + count) % count ))
    next_index=$(( (index + 1) % count ))
    prev_id="$(awk -v n=$((prev_index + 1)) '{ print $n }' <<< "$list")"
    next_id="$(awk -v n=$((next_index + 1)) '{ print $n }' <<< "$list")"
    prev_name="$(tmux display-message -p -t "$prev_id" '#{session_name}' 2>/dev/null || true)"
    next_name="$(tmux display-message -p -t "$next_id" '#{session_name}' 2>/dev/null || true)"
    cycle_indicator="$(format_cycle_indicator "$prev_name" "$next_name")"
  fi
fi

tmux set-option -gq @session_title_indicator "$title_indicator"
tmux set-option -gq @session_cycle_indicator "$cycle_indicator"
