#!/usr/bin/env bash

# Forward typed yabai and layout events to the persistent SbarLua controller.

set -o pipefail

append_if_set() {
  local key="$1"
  local value="$2"

  [[ -n "${value}" ]] && event_arguments+=("${key}=${value}")
}

main() {
  local event="${1:-}"
  local source="${2:-yabai}"
  local status="${3:-}"
  local scope="${4:-}"
  local -a event_arguments

  [[ -n "${event}" ]] || return 1
  command -v sketchybar >/dev/null 2>&1 || return 0

  event_arguments=(
    --trigger yabai_event
    "SOURCE=${source}"
    "EVENT=${event}"
  )
  append_if_set STATUS "${status}"
  append_if_set SCOPE "${scope}"
  append_if_set WINDOW_ID "${YABAI_WINDOW_ID:-}"
  append_if_set SPACE_ID "${YABAI_SPACE_ID:-}"
  append_if_set SPACE_INDEX "${YABAI_SPACE_INDEX:-}"
  append_if_set RECENT_SPACE_ID "${YABAI_RECENT_SPACE_ID:-}"
  append_if_set RECENT_SPACE_INDEX "${YABAI_RECENT_SPACE_INDEX:-}"
  append_if_set DISPLAY_ID "${YABAI_DISPLAY_ID:-}"
  append_if_set DISPLAY_INDEX "${YABAI_DISPLAY_INDEX:-}"
  append_if_set RECENT_DISPLAY_ID "${YABAI_RECENT_DISPLAY_ID:-}"
  append_if_set RECENT_DISPLAY_INDEX "${YABAI_RECENT_DISPLAY_INDEX:-}"

  sketchybar "${event_arguments[@]}" >/dev/null 2>&1 || return 0
}

main "$@"
