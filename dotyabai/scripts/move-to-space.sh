#!/usr/bin/env bash

# Move the focused window to a space and follow. Source repair remains lazy.
# Usage: move-to-space.sh <space-selector>

# shellcheck source=layout-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/layout-lib.sh"

main() {
  local space_selector="${1:-}"
  local window_json
  local window_id
  local source_space_index
  local destination_space_index
  local destination_display_index
  local space_json

  [[ -n "${space_selector}" ]] || return 1
  layout_require_commands || return 0

  window_json="$(yabai -m query --windows --window 2>/dev/null)" || return 0
  window_id="$(jq -r '.id // empty' <<<"${window_json}")"
  source_space_index="$(jq -r '.space // empty' <<<"${window_json}")"
  [[ -n "${window_id}" && -n "${source_space_index}" ]] || return 0

  if ! space_json="$(layout_query_space "${space_selector}")"; then
    case "${space_selector}" in
      prev)
        space_json="$(layout_query_space last)" || return 0
        ;;
      next)
        space_json="$(layout_query_space first)" || return 0
        ;;
      *)
        return 0
        ;;
    esac
  fi
  destination_space_index="$(jq -r '.index // empty' <<<"${space_json}")"
  destination_display_index="$(jq -r '.display // empty' <<<"${space_json}")"
  [[ -n "${destination_space_index}" && -n "${destination_display_index}" ]] || return 0

  if [[ "${source_space_index}" != "${destination_space_index}" ]]; then
    yabai -m window \
      "${window_id}" \
      --space "${destination_space_index}" || return 0
  fi
  yabai -m space --focus "${destination_space_index}" || return 0

  # The destination signal may invoke the same command concurrently; the
  # shared layout lock coalesces that into one pending rerun.
  "${LAYOUT_SCRIPT_DIR}/apply-layout.sh"
}

main "$@"
