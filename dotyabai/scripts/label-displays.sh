#!/usr/bin/env sh

# Label displays by physical left-to-right position.
# Labels:
#   display-1 = leftmost
#   display-2 = next display to the right
#   display-3 = next display to the right

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

i=1
yabai -m query --displays 2>/dev/null |
  jq -r 'sort_by(.frame.x) | .[] | .index' |
  while IFS= read -r display_index; do
    [ -n "$display_index" ] || continue
    yabai -m display "$display_index" --label "display-$i" 2>/dev/null
    i=$((i + 1))
  done
