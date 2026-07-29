#!/usr/bin/env bash

# Label displays and spaces by physical left-to-right display position.
# Labels:
#   display-1 = leftmost display
#   display-2 = next display to the right
#   space-1   = first space on leftmost display, sorted by mission-control index
#   space-2   = next space in left-to-right display order, then space index order

set -o pipefail

main() {
  local should_notify=false
  local displays_json
  local spaces_json
  local label_number=1
  local display_index
  local space_index
  local display_count
  local space_count
  local message

  case "${1:-}" in
    --notify|-n)
      should_notify=true
      ;;
  esac

  command -v yabai >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0

  # Query once so labels are computed from a consistent snapshot.
  displays_json="$(yabai -m query --displays 2>/dev/null)" || return 0
  spaces_json="$(yabai -m query --spaces 2>/dev/null)" || return 0
  [[ -n "${displays_json}" && -n "${spaces_json}" ]] || return 0

  while IFS= read -r display_index; do
    [[ -n "${display_index}" ]] || continue
    yabai -m display \
      "${display_index}" \
      --label "display-${label_number}" 2>/dev/null
    ((label_number += 1))
  done < <(
    jq -r 'sort_by(.frame.x) | .[] | .index' <<<"${displays_json}"
  )

  label_number=1
  while IFS= read -r space_index; do
    [[ -n "${space_index}" ]] || continue
    yabai -m space \
      "${space_index}" \
      --label "space-${label_number}" 2>/dev/null
    ((label_number += 1))
  done < <(
    jq \
      -nr \
      --argjson displays "${displays_json}" \
      --argjson spaces "${spaces_json}" '
        $displays
        | sort_by(.frame.x)
        | .[] as $display
        | (
            $spaces
            | map(select(.display == $display.index))
            | sort_by(.index)
            | .[]
            | .index
          )
      '
  )

  if [[ "${should_notify}" == "true" ]] &&
    command -v osascript >/dev/null 2>&1; then
    display_count="$(jq 'length' <<<"${displays_json}")"
    space_count="$(jq 'length' <<<"${spaces_json}")"
    message="Labelled ${display_count} displays and ${space_count} spaces."
    osascript \
      -e 'on run argv' \
      -e 'display notification (item 1 of argv) with title "yabai" subtitle "Labels refreshed"' \
      -e 'end run' \
      "${message}" \
      >/dev/null 2>&1
  fi
}

main "$@"
