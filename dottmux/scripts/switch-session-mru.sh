#!/usr/bin/env bash
set -eo pipefail

# Maintain one server-wide session MRU and one delayed switch preview.
# The newest client preview replaces any older one without switching it.
# Release or inactivity timeout commits the selected session.

ACTION="${1:-}"
LOCK_NAME="session-switcher"
TIMEOUT_SECONDS=5
VIEWPORT_SIZE=5
DEFAULT_SESSION_NAME_LIMIT=24
SESSION_NAME_TRIM_MARKER='…'
SCRIPT_PATH="${BASH_SOURCE[0]}"
LOCK_HELD=0

usage() {
  printf 'usage: %s record CLIENT_NAME | next|prev CLIENT_NAME CLIENT_PID SESSION_ID | release CLIENT_NAME CLIENT_PID | timeout CLIENT_NAME CLIENT_PID TOKEN\n' "$0" >&2
  exit 2
}

release_lock() {
  if [ "$LOCK_HELD" = "1" ]; then
    LOCK_HELD=0
    tmux wait-for -U "$LOCK_NAME" >/dev/null 2>&1 || true
  fi
}

acquire_lock() {
  tmux wait-for -L "$LOCK_NAME"
  LOCK_HELD=1
  trap release_lock EXIT HUP INT TERM
}

read_option() {
  tmux show-option -gqv "$1" 2>/dev/null || true
}

join_session_ids() {
  local IFS=' '
  printf '%s' "$*"
}

shell_quote() {
  local value="$1"
  value="${value//\'/\'\\\'\'}"
  printf "'%s'" "$value"
}

load_live_sessions() {
  local id name

  live_session_ids=()
  live_session_names=()
  while IFS=$'\t' read -r id name; do
    [[ "$id" =~ ^\$[0-9]+$ ]] || continue
    live_session_ids+=("$id")
    live_session_names+=("$name")
  done < <(tmux list-sessions -F $'#{session_id}\t#{session_name}' 2>/dev/null || true)
}

is_live_session() {
  local session_id="$1" live_session_id

  for live_session_id in "${live_session_ids[@]}"; do
    if [ "$live_session_id" = "$session_id" ]; then
      return 0
    fi
  done
  return 1
}

lookup_session_name() {
  local session_id="$1" i

  resolved_session_name=''
  for ((i = 0; i < ${#live_session_ids[@]}; i += 1)); do
    if [ "${live_session_ids[$i]}" = "$session_id" ]; then
      resolved_session_name="${live_session_names[$i]}"
      return 0
    fi
  done
  return 1
}

resolve_session_name_limit() {
  local limit

  limit="$(read_option @session_name_limit)"
  if ! [[ "$limit" =~ ^[1-9][0-9]*$ ]]; then
    limit="$DEFAULT_SESSION_NAME_LIMIT"
  fi
  printf '%s' "$limit"
}

trim_session_name() {
  local name="$1" limit="$2"

  if [ "${#name}" -gt "$limit" ]; then
    printf '%s%s' "$SESSION_NAME_TRIM_MARKER" "${name: -limit}"
  else
    printf '%s' "$name"
  fi
}

array_contains() {
  local wanted="$1"
  shift
  local item

  for item in "$@"; do
    [ "$item" = "$wanted" ] && return 0
  done
  return 1
}

promote_session_in_mru() {
  local recent_session_id="$1" stored_mru session_id
  local stored_session_ids=()

  mru_session_ids=()
  stored_mru="$(read_option @session_mru)"
  if [ -n "$stored_mru" ]; then
    read -r -a stored_session_ids <<< "$stored_mru"
  fi

  if [[ "$recent_session_id" =~ ^\$[0-9]+$ ]] &&
     is_live_session "$recent_session_id"; then
    mru_session_ids+=("$recent_session_id")
  fi

  for session_id in "${stored_session_ids[@]}"; do
    [[ "$session_id" =~ ^\$[0-9]+$ ]] || continue
    is_live_session "$session_id" || continue
    array_contains "$session_id" "${mru_session_ids[@]}" && continue
    mru_session_ids+=("$session_id")
  done

  for session_id in "${live_session_ids[@]}"; do
    array_contains "$session_id" "${mru_session_ids[@]}" && continue
    mru_session_ids+=("$session_id")
  done

  tmux set-option -gq @session_mru \
    "$(join_session_ids "${mru_session_ids[@]}")"
}

resolve_client_session_id() {
  local required_client_name="$1" required_client_pid="$2"
  local client_name client_pid session_id

  resolved_session_id=''
  while IFS=$'\t' read -r client_name client_pid session_id; do
    if [ "$client_name" = "$required_client_name" ] &&
       { [ -z "$required_client_pid" ] ||
         [ "$client_pid" = "$required_client_pid" ]; }; then
      resolved_session_id="$session_id"
      return 0
    fi
  done < <(tmux list-clients -F $'#{client_name}\t#{client_pid}\t#{session_id}' 2>/dev/null || true)
  return 1
}

clear_preview() {
  tmux \
    set-option -gqu @session_switcher_client_pid \; \
    set-option -gqu @session_switcher_state \; \
    set-option -gqu @session_switcher_view
}

publish_preview() {
  local client_pid="$1" serialized_state="$2" preview_text="$3"

  tmux \
    set-option -gqu @session_switcher_client_pid \; \
    set-option -gq @session_switcher_state "$serialized_state" \; \
    set-option -gq @session_switcher_view "$preview_text" \; \
    set-option -gq @session_switcher_client_pid "$client_pid"
}

read_preview_state() {
  local serialized_state

  preview_token=''
  selected_index=''
  view_start=''
  frozen_session_ids=''
  serialized_state="$(read_option @session_switcher_state)"
  if [ -n "$serialized_state" ]; then
    read -r preview_token selected_index view_start frozen_session_ids \
      <<< "$serialized_state"
  fi
}

render_preview() {
  local count="${#preview_session_ids[@]}"
  local visible_count="$count"
  local end i session_name_limit

  if [ "$visible_count" -gt "$VIEWPORT_SIZE" ]; then
    visible_count="$VIEWPORT_SIZE"
  fi
  end=$((view_start + visible_count))
  session_name_limit="$(resolve_session_name_limit)"
  preview_text=''

  for ((i = view_start; i < end; i += 1)); do
    lookup_session_name "${preview_session_ids[$i]}" || return 1
    resolved_session_name="$(trim_session_name "$resolved_session_name" "$session_name_limit")"
    if [ -n "$preview_text" ]; then
      preview_text="$preview_text | "
    fi
    if [ "$i" -eq "$selected_index" ]; then
      preview_text="${preview_text}*${resolved_session_name}"
    else
      preview_text="${preview_text}${resolved_session_name}"
    fi
  done
}

update_viewport() {
  local direction="$1" count="$2" index="$3" max_start

  if [ "$count" -le "$VIEWPORT_SIZE" ]; then
    view_start=0
    return
  fi

  max_start=$((count - VIEWPORT_SIZE))

  if [ "$direction" = "next" ]; then
    if [ "$index" -eq 0 ]; then
      view_start=0
    elif [ "$index" -lt "$view_start" ] ||
         [ "$index" -ge $((view_start + VIEWPORT_SIZE - 1)) ]; then
      view_start=$((index - VIEWPORT_SIZE + 2))
    fi
  else
    if [ "$index" -eq $((count - 1)) ]; then
      view_start="$max_start"
    elif [ "$index" -gt $((view_start + VIEWPORT_SIZE - 1)) ]; then
      view_start=$((index - VIEWPORT_SIZE + 1))
    elif [ "$index" -le "$view_start" ]; then
      view_start=$((index - 1))
    fi
  fi

  if [ "$view_start" -lt 0 ]; then
    view_start=0
  elif [ "$view_start" -gt "$max_start" ]; then
    view_start="$max_start"
  fi
}

schedule_timeout() {
  local client_name="$1" client_pid="$2" preview_token="$3" command

  command="$(shell_quote "$SCRIPT_PATH") timeout \
$(shell_quote "$client_name") $(shell_quote "$client_pid") $(shell_quote "$preview_token")"
  tmux run-shell -b -d "$TIMEOUT_SECONDS" "$command"
}

record_client_session() {
  local client_name="$1"

  [ -n "$client_name" ] || return
  acquire_lock
  load_live_sessions
  resolve_client_session_id "$client_name" '' || return
  promote_session_in_mru "$resolved_session_id"
}

navigate() {
  local direction="$1" client_name="$2" client_pid="$3"
  local captured_session_id="$4"
  local preview_client_pid frozen_session_ids preview_token preview_text
  local preview_session_ids=()
  local serialized_state
  local continuing=0
  local count index

  [[ "$client_pid" =~ ^[0-9]+$ ]] || return
  [[ "$captured_session_id" =~ ^\$[0-9]+$ ]] || return

  acquire_lock
  load_live_sessions

  preview_client_pid="$(read_option @session_switcher_client_pid)"
  read_preview_state

  if [ "$preview_client_pid" = "$client_pid" ] &&
     [ -n "$frozen_session_ids" ] &&
     [[ "$selected_index" =~ ^[0-9]+$ ]] &&
     [[ "$view_start" =~ ^[0-9]+$ ]] &&
     [ -n "$preview_token" ]; then
    read -r -a preview_session_ids <<< "$frozen_session_ids"
    count="${#preview_session_ids[@]}"
    if [ "$count" -ge 2 ] &&
       [ "$selected_index" -lt "$count" ] &&
       [ "${preview_session_ids[0]-}" = "$captured_session_id" ]; then
      continuing=1
    fi
  fi

  if [ "$continuing" != "1" ]; then
    clear_preview
    resolve_client_session_id "$client_name" "$client_pid" || return
    [ "$resolved_session_id" = "$captured_session_id" ] || return
    is_live_session "$captured_session_id" || return
    promote_session_in_mru "$captured_session_id"
    preview_session_ids=("${mru_session_ids[@]}")
    count="${#preview_session_ids[@]}"
    if [ "$count" -lt 2 ]; then
      return
    fi
    selected_index=0
    if [ "$direction" = "next" ]; then
      view_start=0
    else
      view_start=$((count > VIEWPORT_SIZE ? count - VIEWPORT_SIZE : 0))
    fi
  fi

  count="${#preview_session_ids[@]}"
  index="$selected_index"

  if [ "$direction" = "next" ]; then
    index=$(( (index + 1) % count ))
  else
    index=$(( (index - 1 + count) % count ))
  fi
  selected_index="$index"
  update_viewport "$direction" "$count" "$index"
  render_preview || {
    clear_preview
    return
  }
  preview_token="$(date +%s)-$$-$RANDOM"
  serialized_state="$preview_token $selected_index $view_start \
$(join_session_ids "${preview_session_ids[@]}")"

  publish_preview "$client_pid" "$serialized_state" "$preview_text"

  schedule_timeout "$client_name" "$client_pid" "$preview_token" || clear_preview
}

finalize() {
  local client_name="$1" client_pid="$2" expected_token="$3"
  local preview_client_pid frozen_session_ids selected_index preview_token
  local preview_session_ids=()
  local origin_id selected_id

  [[ "$client_pid" =~ ^[0-9]+$ ]] || return
  [ -n "$expected_token" ] || return

  acquire_lock
  preview_client_pid="$(read_option @session_switcher_client_pid)"
  read_preview_state

  if [ "$preview_client_pid" != "$client_pid" ] ||
     [ "$preview_token" != "$expected_token" ] ||
     [ -z "$frozen_session_ids" ]; then
    return
  fi

  read -r -a preview_session_ids <<< "$frozen_session_ids"
  origin_id="${preview_session_ids[0]-}"
  if ! [[ "$selected_index" =~ ^[0-9]+$ ]] ||
     [ "$selected_index" -ge "${#preview_session_ids[@]}" ]; then
    clear_preview
    return
  fi
  selected_id="${preview_session_ids[$selected_index]}"
  load_live_sessions

  if ! [[ "$origin_id" =~ ^\$[0-9]+$ ]] ||
     ! [[ "$selected_id" =~ ^\$[0-9]+$ ]] ||
     ! is_live_session "$origin_id" ||
     ! is_live_session "$selected_id" ||
     ! resolve_client_session_id "$client_name" "$client_pid" ||
     [ "$resolved_session_id" != "$origin_id" ]; then
    clear_preview
    return
  fi

  clear_preview
  tmux switch-client -c "$client_name" -t "$selected_id"
}

case "$ACTION:$#" in
  record:2)
    record_client_session "$2"
    ;;
  next:4|prev:4)
    navigate "$ACTION" "$2" "$3" "$4"
    ;;
  release:3)
    read_preview_state
    expected_token="$preview_token"
    [ -n "$expected_token" ] || exit 0
    sleep 0.05
    finalize "$2" "$3" "$expected_token"
    ;;
  timeout:4)
    finalize "$2" "$3" "$4"
    ;;
  *)
    usage
    ;;
esac
