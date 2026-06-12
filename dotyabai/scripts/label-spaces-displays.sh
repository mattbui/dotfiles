#!/usr/bin/env sh

# Label displays and spaces by physical left-to-right display position.
# Labels:
#   display-1 = leftmost display
#   display-2 = next display to the right
#   space-1   = first space on leftmost display, sorted by mission-control index
#   space-2   = next space in left-to-right display order, then space index order

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Query once so display and space labels are computed from a consistent snapshot.
displays_json="$(yabai -m query --displays 2>/dev/null)" || exit 0
spaces_json="$(yabai -m query --spaces 2>/dev/null)" || exit 0

[ -n "$displays_json" ] || exit 0
[ -n "$spaces_json" ] || exit 0

# Label displays by physical left-to-right order.
i=1
printf '%s\n' "$displays_json" |
  jq -r 'sort_by(.frame.x) | .[] | .index' |
  while IFS= read -r display_index; do
    [ -n "$display_index" ] || continue
    yabai -m display "$display_index" --label "display-$i" 2>/dev/null
    i=$((i + 1))
  done

# Label spaces by left-to-right display order, then by mission-control space index.
i=1
jq -nr --argjson displays "$displays_json" --argjson spaces "$spaces_json" '
  $displays
  | sort_by(.frame.x)
  | .[] as $display
  | ($spaces | map(select(.display == $display.index)) | sort_by(.index) | .[] | .index)
' |
  while IFS= read -r space_index; do
    [ -n "$space_index" ] || continue
    yabai -m space "$space_index" --label "space-$i" 2>/dev/null
    i=$((i + 1))
  done
