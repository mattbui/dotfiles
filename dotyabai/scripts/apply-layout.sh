#!/usr/bin/env bash

# Reconcile the current space with the flexible layout.
# Usage: apply-layout.sh [reset]

set -o pipefail

# shellcheck source=layout-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/layout-lib.sh"

layout_lock_dir=""
layout_pending_file=""

acquire_lock() {
  layout_lock_dir="${LAYOUT_STATE_ROOT}/layout.lock"
  layout_pending_file="${LAYOUT_STATE_ROOT}/layout.pending"

  mkdir -p "${LAYOUT_STATE_ROOT}" 2>/dev/null || return 1
  if ! mkdir "${layout_lock_dir}" 2>/dev/null; then
    : >"${layout_pending_file}" 2>/dev/null
    return 1
  fi
}

release_lock() {
  local status=$?

  trap - EXIT INT TERM
  rmdir "${layout_lock_dir}" 2>/dev/null
  if [[ -f "${layout_pending_file}" ]]; then
    rm -f "${layout_pending_file}" 2>/dev/null
    "$0" >/dev/null 2>&1 &
  fi
  exit "${status}"
}

window_is_floating() {
  yabai -m query --windows --window "$1" 2>/dev/null |
    jq -e '."is-floating" == true' >/dev/null 2>&1
}

create_second_region() {
  local windows="$1"
  local preferred_id
  local anchor_id
  local updated_windows
  local preferred_region

  preferred_id="$(layout_preferred_window_id "${windows}")"
  [[ -n "${preferred_id}" ]] || return 1
  anchor_id="$(layout_stable_id_except "${windows}" "${preferred_id}")"
  [[ -n "${anchor_id}" ]] || return 1

  yabai -m window \
    "${anchor_id}" \
    --insert "${layout_extract_direction}" 2>/dev/null || return 1
  yabai -m window "${preferred_id}" --toggle float 2>/dev/null || return 1
  if ! window_is_floating "${preferred_id}"; then
    yabai -m window \
      "${anchor_id}" \
      --insert "${layout_extract_direction}" >/dev/null 2>&1 || :
    return 1
  fi

  if ! yabai -m window "${preferred_id}" --toggle float 2>/dev/null; then
    yabai -m window \
      "${preferred_id}" \
      --toggle float >/dev/null 2>&1 || return 1
  fi
  if window_is_floating "${preferred_id}"; then
    yabai -m window \
      "${preferred_id}" \
      --toggle float >/dev/null 2>&1 || return 1
  fi
  window_is_floating "${preferred_id}" && return 1

  updated_windows="$(layout_query_candidate_windows)" || return 1
  preferred_region="$(
    layout_region_for_id "${updated_windows}" "${preferred_id}"
  )"
  if [[ "${preferred_region}" == "first" ]]; then
    yabai -m window \
      "${preferred_id}" \
      --swap "${layout_extract_direction}" 2>/dev/null || return 1
  fi
}

stack_extra_regions_into_first() {
  local windows="$1"
  local second_region_bounds
  local anchor_id
  local anchor_region_bounds
  local stack_ids
  local id

  second_region_bounds="$(layout_second_region_bounds "${windows}")"
  anchor_id="$(
    layout_anchor_id_outside_region "${windows}" "${second_region_bounds}"
  )"
  [[ -n "${anchor_id}" ]] || return 1
  anchor_region_bounds="$(layout_region_bounds_for_id "${windows}" "${anchor_id}")"
  stack_ids="$(
    layout_window_ids_outside_regions \
      "${windows}" \
      "${anchor_region_bounds}" \
      "${second_region_bounds}"
  )"

  while IFS= read -r id; do
    [[ -n "${id}" ]] || continue
    yabai -m window "${anchor_id}" --stack "${id}" 2>/dev/null || return 1
  done <<<"${stack_ids}"
}

reconcile_two_stack() {
  local windows="$1"
  local region_count
  local axis_region_count
  local cross_axis_region_count
  local target_axis
  local split_window_id

  region_count="$(layout_region_count "${windows}")"
  axis_region_count="$(layout_axis_region_count "${windows}")"
  cross_axis_region_count="$(layout_cross_axis_region_count "${windows}")"

  # Repair extra leaves on the old axis before rotating the root split.
  if (( axis_region_count == 1 && cross_axis_region_count >= 2 )); then
    target_axis="${layout_axis}"
    if [[ "${layout_axis}" == "x" ]]; then
      layout_axis="y"
    else
      layout_axis="x"
    fi
    if ! stack_extra_regions_into_first "${windows}"; then
      layout_axis="${target_axis}"
      return 1
    fi
    layout_axis="${target_axis}"

    windows="$(layout_query_candidate_windows)" || return 1
    region_count="$(layout_region_count "${windows}")"
    axis_region_count="$(layout_axis_region_count "${windows}")"
    cross_axis_region_count="$(layout_cross_axis_region_count "${windows}")"
    (( region_count == 2 && axis_region_count == 1 && cross_axis_region_count == 2 )) ||
      return 1

    split_window_id="$(layout_preferred_window_id "${windows}")"
    [[ -n "${split_window_id}" ]] || return 1
    yabai -m window "${split_window_id}" --toggle split 2>/dev/null || return 1

    windows="$(layout_query_candidate_windows)" || return 1
    layout_is_valid_two_stack "${windows}" && return 0
    region_count="$(layout_region_count "${windows}")"
    axis_region_count="$(layout_axis_region_count "${windows}")"
  fi

  if (( region_count == 1 || axis_region_count < 2 )); then
    create_second_region "${windows}"
    return
  fi
  if (( region_count == 2 && axis_region_count == 2 )); then
    return 0
  fi

  stack_extra_regions_into_first "${windows}"
}

apply_split_ratio() {
  local windows="$1"
  local desired_split_ratio="$2"
  local second_region_bounds
  local second_region_window_id
  local first_region_bounds
  local first_region_window_id
  local first_region_size
  local second_region_size

  second_region_bounds="$(layout_second_region_bounds "${windows}")"
  second_region_window_id="$(
    layout_window_id_in_region "${windows}" "${second_region_bounds}"
  )"
  first_region_bounds="$(layout_first_region_bounds "${windows}")"
  first_region_window_id="$(
    layout_window_id_in_region "${windows}" "${first_region_bounds}"
  )"
  [[ -n "${first_region_window_id}" ]] || return 1
  [[ -n "${second_region_window_id}" ]] || return 1

  first_region_size="$(
    layout_axis_size_for_id "${windows}" "${first_region_window_id}"
  )"
  second_region_size="$(
    layout_axis_size_for_id "${windows}" "${second_region_window_id}"
  )"
  if ! layout_ratio_is_compliant \
    "${first_region_size}" \
    "${second_region_size}" \
    "${desired_split_ratio}"; then
    yabai -m window \
      "${second_region_window_id}" \
      --ratio abs:"${desired_split_ratio}" 2>/dev/null || return 1
  fi
}

main() {
  local candidate_windows
  local candidate_count
  local region_count
  local arrangement
  local desired_space_type
  local desired_split_ratio
  local display_profile
  local preferences
  local single_stack_sizing
  local arrangement_settings
  local current_split_ratio

  (( $# <= 1 )) || return 1
  [[ -z "${1:-}" || "$1" == "reset" ]] || return 1

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
  layout_extract_direction="$(jq -r '.extract_direction' <<<"${display_profile}")"
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

  if [[ "${1:-}" == "reset" ]]; then
    [[ -n "${layout_state_file}" ]] || return 0
    layout_single_width_ratio="${LAYOUT_DEFAULT_SINGLE_WIDTH_RATIO}"
    layout_single_height_ratio="${LAYOUT_DEFAULT_SINGLE_HEIGHT_RATIO}"
    layout_landscape_split_ratio="${LAYOUT_DEFAULT_LANDSCAPE_SPLIT_RATIO}"
    layout_portrait_split_ratio="${LAYOUT_DEFAULT_PORTRAIT_SPLIT_RATIO}"
  fi

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

  if [[ "${arrangement}" != "single-stack" ]]; then
    desired_split_ratio="$(layout_split_ratio_for_orientation)"
    current_split_ratio="$(yabai -m config split_ratio 2>/dev/null)"
  fi
  if layout_is_compliant \
    "${arrangement}" \
    "${desired_space_type}" \
    "${candidate_windows}" \
    "${region_count}"; then
    if [[ "${arrangement}" == "single-stack" ]] ||
      layout_ratio_values_match \
        "${current_split_ratio}" \
        "${desired_split_ratio}"; then
      layout_save_preferences 2>/dev/null
      return 0
    fi
  fi

  acquire_lock || return 0
  trap release_lock EXIT INT TERM

  if [[ "${arrangement}" == "single-stack" ]]; then
    layout_apply_space_settings \
      stack \
      "${layout_gap}" \
      "${layout_padding_top}" \
      "${layout_padding_bottom}" \
      "${layout_padding_left}" \
      "${layout_padding_right}" || return 0
    layout_save_preferences 2>/dev/null
    return 0
  fi

  layout_apply_config_if_needed \
    split_type \
    "${layout_split_type}" || return 0
  yabai -m config split_ratio "${desired_split_ratio}" || return 0

  if [[ "${arrangement}" == "temporary-single-stack" ]]; then
    layout_apply_space_settings \
      bsp \
      "${layout_gap}" \
      "${layout_padding_top}" \
      "${layout_padding_bottom}" \
      "${layout_padding_left}" \
      "${layout_padding_right}" || return 0
    layout_save_preferences 2>/dev/null
    return 0
  fi

  layout_apply_space_settings \
    bsp \
    "${layout_gap}" \
    "${LAYOUT_TOP_PADDING}" \
    "${layout_base_padding}" \
    "${layout_base_padding}" \
    "${layout_base_padding}" || return 0

  candidate_windows="$(layout_query_candidate_windows)" || return 0
  reconcile_two_stack "${candidate_windows}" || return 0
  candidate_windows="$(layout_query_candidate_windows)" || return 0
  layout_is_valid_two_stack "${candidate_windows}" || return 0
  apply_split_ratio "${candidate_windows}" "${desired_split_ratio}" || return 0
  layout_save_preferences 2>/dev/null
}

main "$@"
