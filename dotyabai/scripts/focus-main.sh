#!/usr/bin/env sh

# Focus after a window is destroyed.
# - stack layout: focus a deterministic window from the current space
# - custom wide/BSP layout: focus saved main window, if it still exists

state_dir="$HOME/.local/state/yabai"
# shellcheck source=/dev/null
. "$(dirname "$0")/layout-state.sh"

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

space_json=$(yabai -m query --spaces --space 2>/dev/null) || exit 0
space_index=$(printf '%s' "$space_json" | jq -r '.index')
space_type=$(printf '%s' "$space_json" | jq -r '.type')
[ -n "$space_index" ] && [ "$space_index" != "null" ] || exit 0

if [ "$space_type" = "stack" ]; then
  target_id=$(printf '%s' "$space_json" | jq -r '."last-window" // ."first-window" // empty')
  if [ -n "$target_id" ] && [ "$target_id" != "0" ] && [ "$target_id" != "null" ]; then
    yabai -m window --focus "$target_id" 2>/dev/null
  fi
  exit 0
fi

layout_state_file=$(layout_state_file_for_space "$space_index")
main_id=$(layout_state_get "$layout_state_file" main_id "")
[ -n "$main_id" ] && [ "$main_id" != "null" ] || exit 0

main_window_json=$(yabai -m query --windows --window "$main_id" 2>/dev/null) || exit 0
main_space=$(printf '%s' "$main_window_json" | jq -r '.space // empty')
main_has_focus=$(printf '%s' "$main_window_json" | jq -r '."has-focus" // false')

if [ "$main_space" = "$space_index" ] && [ "$main_has_focus" != "true" ]; then
  yabai -m window --focus "$main_id" 2>/dev/null
fi
