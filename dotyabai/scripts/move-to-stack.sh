#!/usr/bin/env bash

# Move the focused eligible tiled window to a two-stack region.
# Usage: move-to-stack.sh left|right|top|bottom

# shellcheck source=layout-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/layout-lib.sh"

main() {
  local target_direction="${1:-}"
  local target_region
  local window_json
  local window_id
  local is_floating
  local is_minimized
  local candidate_windows
  local current_region
  local first_region_bounds
  local second_region_bounds
  local target_region_bounds
  local source_region_bounds
  local target_windows
  local source_windows
  local target_count
  local source_count
  local target_anchor_id
  local replacement_id
  local display_profile
  local preferences

  case "${target_direction}" in
    left|right|top|bottom) ;;
    *) return 1 ;;
  esac

  layout_require_commands || return 0
  layout_space_json="$(layout_query_space)" || return 0
  layout_space_index="$(jq -r '.index // empty' <<<"${layout_space_json}")"
  layout_space_label="$(jq -r '.label // empty' <<<"${layout_space_json}")"
  layout_space_display_index="$(jq -r '.display // empty' <<<"${layout_space_json}")"
  [[ -n "${layout_space_index}" && -n "${layout_space_display_index}" ]] || return 0
  layout_state_file="$(
    layout_state_file_for_label "${layout_space_label}"
  )"

  layout_display_json="$(
    layout_query_display "${layout_space_display_index}"
  )" || return 0
  layout_display_w="$(jq -r '.frame.w // empty' <<<"${layout_display_json}")"
  layout_display_h="$(jq -r '.frame.h // empty' <<<"${layout_display_json}")"
  [[ -n "${layout_display_w}" && -n "${layout_display_h}" ]] || return 0
  display_profile="$(
    layout_resolve_display_profile "${layout_display_w}" "${layout_display_h}"
  )" || return 0
  layout_area_class="$(jq -r '.area_class' <<<"${display_profile}")"
  layout_orientation="$(jq -r '.orientation' <<<"${display_profile}")"
  layout_axis="$(jq -r '.axis' <<<"${display_profile}")"

  preferences="$(
    layout_resolve_preferences "${layout_state_file}" "${layout_area_class}"
  )" || return 0
  layout_mode="$(jq -r '.mode' <<<"${preferences}")"

  case "${layout_orientation}:${target_direction}" in
    landscape:left|portrait:top)
      target_region="first"
      ;;
    landscape:right|portrait:bottom)
      target_region="second"
      ;;
    *)
      return 0
      ;;
  esac
  [[ "${layout_mode}" == "two-stack" ]] || return 0

  window_json="$(yabai -m query --windows --window 2>/dev/null)" || return 0
  window_id="$(jq -r '.id // empty' <<<"${window_json}")"
  is_floating="$(jq -r '."is-floating"' <<<"${window_json}")"
  is_minimized="$(jq -r '."is-minimized"' <<<"${window_json}")"
  [[
    -n "${window_id}" &&
      "${is_floating}" == "false" &&
      "${is_minimized}" == "false"
  ]] || return 0

  # Repair a collapsed, rotated, or manually altered tree before interpreting it.
  "${LAYOUT_SCRIPT_DIR}/apply-layout.sh" || return 0
  candidate_windows="$(layout_query_candidate_windows)" || return 0
  layout_is_valid_two_stack "${candidate_windows}" || return 0

  current_region="$(
    layout_region_for_id "${candidate_windows}" "${window_id}"
  )"
  [[ -n "${current_region}" ]] || return 0
  [[ "${current_region}" != "${target_region}" ]] || return 0

  first_region_bounds="$(layout_first_region_bounds "${candidate_windows}")"
  second_region_bounds="$(layout_second_region_bounds "${candidate_windows}")"
  if [[ "${target_region}" == "first" ]]; then
    target_region_bounds="${first_region_bounds}"
    source_region_bounds="${second_region_bounds}"
  else
    target_region_bounds="${second_region_bounds}"
    source_region_bounds="${first_region_bounds}"
  fi

  target_windows="$(
    layout_windows_in_region "${candidate_windows}" "${target_region_bounds}"
  )"
  source_windows="$(
    layout_windows_in_region "${candidate_windows}" "${source_region_bounds}"
  )"
  target_count="$(layout_candidate_count "${target_windows}")"
  source_count="$(layout_candidate_count "${source_windows}")"
  target_anchor_id="$(
    layout_window_id_in_region "${candidate_windows}" "${target_region_bounds}"
  )"
  [[ -n "${target_anchor_id}" ]] || return 0

  if (( source_count > 1 )); then
    yabai -m window \
      "${target_anchor_id}" \
      --stack "${window_id}" 2>/dev/null || return 0
  elif (( target_count == 1 )); then
    yabai -m window \
      "${window_id}" \
      --swap "${target_anchor_id}" 2>/dev/null || return 0
  else
    replacement_id="$(
      layout_replacement_id "${target_windows}" "${target_anchor_id}"
    )"
    [[ -n "${replacement_id}" ]] || return 0
    yabai -m window \
      "${replacement_id}" \
      --warp "${window_id}" 2>/dev/null || return 0
    yabai -m window \
      "${target_anchor_id}" \
      --stack "${window_id}" 2>/dev/null || return 0
  fi

  yabai -m window "${window_id}" --focus 2>/dev/null || :
  "${LAYOUT_SCRIPT_DIR}/apply-layout.sh"
}

main "$@"
