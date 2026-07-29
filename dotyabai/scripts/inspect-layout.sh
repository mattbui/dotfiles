#!/usr/bin/env bash

# Show the current flexible-layout status as a notification.

set -o pipefail

# shellcheck source=layout-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/layout-lib.sh"

window_summary() {
  local arrangement="$1"
  local windows="$2"
  local candidate_count="$3"
  local first_region_bounds
  local second_region_bounds
  local first_region_window_count
  local second_region_window_count

  if [[ "${arrangement}" == "two-stack" ]] &&
    layout_is_valid_two_stack "${windows}"; then
    first_region_bounds="$(layout_first_region_bounds "${windows}")"
    second_region_bounds="$(layout_second_region_bounds "${windows}")"
    first_region_window_count="$(
      layout_candidate_count \
        "$(layout_windows_in_region "${windows}" "${first_region_bounds}")"
    )"
    second_region_window_count="$(
      layout_candidate_count \
        "$(layout_windows_in_region "${windows}" "${second_region_bounds}")"
    )"
    printf '%s: %s · %s: %s' \
      "${layout_first_region_name}" \
      "${first_region_window_count}" \
      "${layout_second_region_name}" \
      "${second_region_window_count}"
  else
    printf 'Tiled: %s' "${candidate_count}"
  fi
}

notify_layout_status() {
  local compliant="$1"
  local arrangement="$2"
  local windows="$3"
  local candidate_count="$4"
  local status
  local summary
  local ratio
  local ratio_summary=""

  command -v osascript >/dev/null 2>&1 || return 0
  if [[ "${compliant}" == "true" ]]; then
    status="✓ Ready"
  else
    status="⚠ Repair with ⌥R"
  fi

  summary="$(window_summary "${arrangement}" "${windows}" "${candidate_count}")"
  ratio="$(layout_ratio_for_arrangement "${arrangement}")"
  [[ -n "${ratio}" ]] && ratio_summary=" · Ratio ${ratio}"

  osascript \
    -e 'on run argv' \
    -e 'display notification (item 1 of argv) with title "yabai" subtitle (item 2 of argv)' \
    -e 'end run' \
    "${summary}${ratio_summary} · ${status}" \
    "Space: ${layout_space_label:-${layout_space_index}} · ${layout_mode}" \
    >/dev/null 2>&1
}

main() {
  local candidate_windows
  local candidate_count
  local region_count
  local arrangement
  local desired_space_type
  local compliant=true
  local status=0
  local display_profile
  local preferences
  local single_stack_sizing
  local arrangement_settings

  (( $# == 0 )) || return 1
  layout_require_commands || return 0

  layout_space_json="$(layout_query_space)" || return 0
  layout_space_index="$(jq -r '.index // empty' <<<"${layout_space_json}")"
  layout_space_label="$(jq -r '.label // empty' <<<"${layout_space_json}")"
  layout_space_type="$(jq -r '.type // empty' <<<"${layout_space_json}")"
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
  layout_base_padding="$(jq -r '.base_padding' <<<"${display_profile}")"
  layout_gap="$(jq -r '.gap' <<<"${display_profile}")"
  layout_orientation="$(jq -r '.orientation' <<<"${display_profile}")"
  layout_axis="$(jq -r '.axis' <<<"${display_profile}")"
  layout_split_type="$(jq -r '.split_type' <<<"${display_profile}")"
  layout_first_region_name="$(jq -r '.first_region_name' <<<"${display_profile}")"
  layout_second_region_name="$(jq -r '.second_region_name' <<<"${display_profile}")"
  layout_is_ultrawide="$(jq -r '.is_ultrawide' <<<"${display_profile}")"

  preferences="$(
    layout_resolve_preferences "${layout_state_file}" "${layout_area_class}"
  )" || return 0
  layout_mode="$(jq -r '.mode' <<<"${preferences}")"
  layout_single_width_ratio="$(
    jq -r '.single_width_ratio' <<<"${preferences}"
  )"
  layout_single_height_ratio="$(
    jq -r '.single_height_ratio' <<<"${preferences}"
  )"
  layout_landscape_split_ratio="$(
    jq -r '.landscape_split_ratio' <<<"${preferences}"
  )"
  layout_portrait_split_ratio="$(
    jq -r '.portrait_split_ratio' <<<"${preferences}"
  )"

  candidate_windows="$(layout_query_candidate_windows)" || return 0
  candidate_count="$(layout_candidate_count "${candidate_windows}")"
  region_count="$(layout_region_count "${candidate_windows}")"
  single_stack_sizing="$(
    layout_resolve_single_stack_sizing \
      "${layout_orientation}" \
      "${layout_display_w}" \
      "${layout_display_h}" \
      "${layout_base_padding}" \
      "${layout_is_ultrawide}" \
      "${layout_single_width_ratio}" \
      "${layout_single_height_ratio}"
  )" || return 0
  layout_effective_single_ratio="$(
    jq -r '.effective_ratio' <<<"${single_stack_sizing}"
  )"
  layout_padding_top="$(jq -r '.padding_top' <<<"${single_stack_sizing}")"
  layout_padding_bottom="$(jq -r '.padding_bottom' <<<"${single_stack_sizing}")"
  layout_padding_left="$(jq -r '.padding_left' <<<"${single_stack_sizing}")"
  layout_padding_right="$(jq -r '.padding_right' <<<"${single_stack_sizing}")"

  arrangement_settings="$(
    layout_resolve_arrangement \
      "${layout_mode}" \
      "${candidate_count}" \
      "${layout_base_padding}" \
      "${layout_padding_top}" \
      "${layout_padding_bottom}" \
      "${layout_padding_left}" \
      "${layout_padding_right}"
  )" || return 0
  arrangement="$(jq -r '.arrangement' <<<"${arrangement_settings}")"
  desired_space_type="$(
    jq -r '.desired_space_type' <<<"${arrangement_settings}"
  )"
  layout_padding_top="$(jq -r '.padding_top' <<<"${arrangement_settings}")"
  layout_padding_bottom="$(jq -r '.padding_bottom' <<<"${arrangement_settings}")"
  layout_padding_left="$(jq -r '.padding_left' <<<"${arrangement_settings}")"
  layout_padding_right="$(jq -r '.padding_right' <<<"${arrangement_settings}")"

  if ! layout_is_compliant \
    "${arrangement}" \
    "${desired_space_type}" \
    "${candidate_windows}" \
    "${region_count}"; then
    compliant=false
    status=1
  fi

  notify_layout_status \
    "${compliant}" \
    "${arrangement}" \
    "${candidate_windows}" \
    "${candidate_count}"
  return "${status}"
}

main "$@"
