#!/usr/bin/env bash

# Label displays and spaces by physical left-to-right display position.
# Labels:
#   display-1 = leftmost display
#   display-2 = next display to the right
#   space-1   = first space on leftmost display, sorted by mission-control index
#   space-2   = next space in left-to-right display order, then space index order

set -o pipefail

# shellcheck source=layout-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/layout-lib.sh"

label_snapshot() {
  local displays_json
  local spaces_json

  displays_json="$(yabai -m query --displays id,index,label,frame,spaces 2>/dev/null)" ||
    return 1
  spaces_json="$(yabai -m query --spaces id,index,label,display 2>/dev/null)" || return 1

  jq -cen --argjson displays "${displays_json}" --argjson spaces "${spaces_json}" '
    def with_labels($kind):
      to_entries | map(.value + {kind: $kind, expected: "\($kind)-\(.key + 1)"});

    ($displays | sort_by(.frame.x, .index)) as $ordered_displays
    | [
        $ordered_displays[] as $display
        | ($spaces | map(select(.display == $display.index)) | sort_by(.index)) as $members
        | if ($members | map(.index)) == ($display.spaces | sort)
          then $members[]
          else error("display and space queries disagree")
          end
      ] as $ordered_spaces
    | select(($ordered_displays | length) > 0 and ($ordered_spaces | length) > 0)
    | select(($ordered_spaces | length) == ($spaces | length))
    | select(($ordered_spaces | map(.index) | unique | length) == ($spaces | length))
    | ($ordered_displays | with_labels("display")) + ($ordered_spaces | with_labels("space"))
  ' 2>/dev/null
}

write_labels() {
  local changes
  local kind
  local index
  local label

  changes="$(jq -r '.[] | select(.label != .expected) | [.kind, .index, .expected] | @tsv' \
    <<<"$1")" || return 1
  [[ -n "${changes}" ]] || return 0
  while IFS=$'\t' read -r kind index label; do
    yabai -m "${kind}" "${index}" --label "${label}" 2>/dev/null || return 1
  done <<<"${changes}"
}

refresh_labels() {
  local previous=""
  local snapshot
  local expected
  local attempt

  # Display and Mission Control indices can change while a monitor reconnects.
  # Wait for two matching observations and verify the writes against a fresh query.
  for ((attempt = 0; attempt < 8; attempt++)); do
    if snapshot="$(label_snapshot)"; then
      if [[ "${snapshot}" == "${previous}" ]] && write_labels "${snapshot}"; then
        expected="$(jq -c 'map(.label = .expected)' <<<"${snapshot}")" || return 1
        [[ "$(label_snapshot)" == "${expected}" ]] && return 0
      fi
      previous="${snapshot}"
    else
      previous=""
    fi
    sleep 0.5
  done
  return 1
}

notify_sketchy_bar_labels_completed() {
  local status="$1"
  local notifier="${HOME}/.config/sketchybar/scripts/forward-yabai-event.sh"

  [[ -x "${notifier}" ]] || return 0
  "${notifier}" labels_completed label_script "${status}" all
}

main() {
  local message="Display and space labels refreshed."
  local status="success"

  layout_require_commands || return 1
  mkdir -p "${LAYOUT_STATE_ROOT}" || return 1
  exec 9>>"${LAYOUT_STATE_ROOT}/labels.lock" || return 1
  if ! /usr/bin/lockf -t 5 9 || ! refresh_labels; then
    status="failed"
    message="Could not verify display and space labels."
  fi
  exec 9>&-

  notify_sketchy_bar_labels_completed "${status}"
  if [[ "${1:-}" == "--notify" || "${1:-}" == "-n" ]]; then
    osascript -e 'on run argv' \
      -e 'display notification (item 1 of argv) with title "yabai"' \
      -e 'end run' "${message}" >/dev/null 2>&1 || :
  fi
  [[ "${status}" == "success" ]]
}

main "$@"
