#!/usr/bin/env sh

# Focus a space only when it belongs to the currently focused display.
# This prevents ctrl-1..9 from jumping focus to a space on another display.

space_index="$1"
[ -n "$space_index" ] || exit 1

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

current_display="$(yabai -m query --displays --display 2>/dev/null | jq -r '.index // empty')"
target_display="$(yabai -m query --spaces 2>/dev/null | jq -r --argjson idx "$space_index" '.[] | select(.index == $idx) | .display')"

[ -n "$current_display" ] || exit 1
[ -n "$target_display" ] || exit 1

if [ "$target_display" = "$current_display" ]; then
  yabai -m space --focus "$space_index"
fi
