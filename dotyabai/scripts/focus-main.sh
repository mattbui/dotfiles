#!/usr/bin/env sh

# Focus after a window is destroyed.
# - stack layout: focus a deterministic window from the current space
# - custom wide/BSP layout: focus saved main window, if it still exists

state_dir="$HOME/.local/state/yabai"

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

space_json=$(yabai -m query --spaces --space 2>/dev/null) || exit 0
space_id=$(printf '%s' "$space_json" | jq -r '.id')
space_type=$(printf '%s' "$space_json" | jq -r '.type')
[ -n "$space_id" ] && [ "$space_id" != "null" ] || exit 0

if [ "$space_type" = "stack" ]; then
  target_id=$(printf '%s' "$space_json" | jq -r '."last-window" // ."first-window" // empty')
  if [ -n "$target_id" ] && [ "$target_id" != "0" ] && [ "$target_id" != "null" ]; then
    yabai -m window --focus "$target_id" 2>/dev/null
  fi
  exit 0
fi

main_file="$state_dir/main-$space_id"
[ -f "$main_file" ] || exit 0
main_id=$(cat "$main_file" 2>/dev/null)
[ -n "$main_id" ] && [ "$main_id" != "null" ] || exit 0

windows_json=$(yabai -m query --windows --space 2>/dev/null) || exit 0
if printf '%s' "$windows_json" | jq -e --argjson id "$main_id" 'any(.[]; .id == $id)' >/dev/null 2>&1; then
  yabai -m window --focus "$main_id" 2>/dev/null
fi
