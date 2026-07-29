#!/usr/bin/env bash

# Resize the focused floating window or active flexible tiled arrangement.
# Usage: resize.sh grow|shrink [multiplier]

# shellcheck source=layout-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/layout-lib.sh"

resize_floating_window() {
  local action="$1"
  local step_pixels="$2"
  local window_json="$3"
  local x
  local y
  local width
  local height
  local delta
  local next_x
  local next_y
  local next_width
  local next_height

  x="$(jq -r '.frame.x' <<<"${window_json}")"
  y="$(jq -r '.frame.y' <<<"${window_json}")"
  width="$(jq -r '.frame.w' <<<"${window_json}")"
  height="$(jq -r '.frame.h' <<<"${window_json}")"
  if [[ "${action}" == "grow" ]]; then
    delta="${step_pixels}"
  else
    delta="-${step_pixels}"
  fi

  read -r next_x next_y next_width next_height < <(
    awk \
      -v x="${x}" \
      -v y="${y}" \
      -v width="${width}" \
      -v height="${height}" \
      -v delta="${delta}" '
        BEGIN {
          next_width = width + delta
          next_height = height + delta
          if (next_width < 300) {
            next_width = 300
          }
          if (next_height < 200) {
            next_height = 200
          }
          next_x = x - ((next_width - width) / 2)
          next_y = y - ((next_height - height) / 2)
          printf "%d %d %d %d", next_x, next_y, next_width, next_height
        }
      '
  )

  yabai -m window --resize abs:"${next_width}":"${next_height}"
  yabai -m window --move abs:"${next_x}":"${next_y}"
}

adjust_saved_ratio() {
  local ratio_key="$1"
  local current_ratio="$2"
  local minimum_ratio="$3"
  local maximum_ratio="$4"
  local ratio_direction="$5"
  local ratio_step="$6"
  local effective_ratio
  local updated_ratio

  effective_ratio="$(
    awk \
      -v value="${current_ratio}" \
      -v maximum="${maximum_ratio}" '
        BEGIN {
          if (value > maximum) {
            value = maximum
          }
          printf "%.3f", value
        }
      '
  )"
  if [[ "${ratio_direction}" == "grow" ]]; then
    updated_ratio="$(
      awk \
        -v value="${effective_ratio}" \
        -v step="${ratio_step}" \
        -v maximum="${maximum_ratio}" '
          BEGIN {
            value += step
            if (value > maximum) {
              value = maximum
            }
            printf "%.3f", value
          }
        '
    )"
  else
    updated_ratio="$(
      awk \
        -v value="${effective_ratio}" \
        -v step="${ratio_step}" \
        -v minimum="${minimum_ratio}" '
          BEGIN {
            value -= step
            if (value < minimum) {
              value = minimum
            }
            printf "%.3f", value
          }
        '
    )"
  fi

  [[ "${updated_ratio}" != "${effective_ratio}" ]] || return 0
  layout_state_update \
    "${layout_state_file}" \
    "${ratio_key}" \
    "${updated_ratio}" 2>/dev/null || return 1
  "${LAYOUT_SCRIPT_DIR}/apply-layout.sh" >/dev/null 2>&1
}

main() {
  local action="${1:-}"
  local multiplier="${2:-1}"
  local ratio_step
  local floating_step_pixels
  local window_json
  local is_floating
  local window_id
  local window_space_index
  local candidate_windows
  local candidate_count
  local max_ratio
  local focused_region
  local ratio_key
  local current_ratio
  local ratio_direction
  local display_profile
  local preferences

  [[ "${action}" == "grow" || "${action}" == "shrink" ]] || return 1
  [[ "${multiplier}" =~ ^[0-9]+$ ]] &&
    (( 10#${multiplier} >= 1 )) || return 1

  layout_require_commands || return 0
  ratio_step="$(
    awk \
      -v step="0.025" \
      -v multiplier="${multiplier}" \
      'BEGIN { printf "%.3f", step * multiplier }'
  )"
  floating_step_pixels=$((80 * 10#${multiplier}))

  window_json="$(yabai -m query --windows --window 2>/dev/null)" || return 0
  [[ -n "${window_json}" ]] || return 0
  is_floating="$(jq -r '."is-floating"' <<<"${window_json}")"

  if [[ "${is_floating}" == "true" ]]; then
    resize_floating_window "${action}" "${floating_step_pixels}" "${window_json}"
    return
  fi

  window_id="$(jq -r '.id // empty' <<<"${window_json}")"
  window_space_index="$(jq -r '.space // empty' <<<"${window_json}")"
  [[ -n "${window_id}" && -n "${window_space_index}" ]] || return 0

  layout_space_json="$(layout_query_space "${window_space_index}")" || return 0
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
  layout_base_padding="$(jq -r '.base_padding' <<<"${display_profile}")"
  layout_orientation="$(jq -r '.orientation' <<<"${display_profile}")"
  layout_axis="$(jq -r '.axis' <<<"${display_profile}")"
  layout_is_ultrawide="$(jq -r '.is_ultrawide' <<<"${display_profile}")"

  [[ -n "${layout_state_file}" ]] || return 0

  if [[ ! -f "${layout_state_file}" ]]; then
    "${LAYOUT_SCRIPT_DIR}/apply-layout.sh" >/dev/null 2>&1 || return 0
  fi
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

  if [[ "${layout_mode}" == "single-stack" ]] ||
    (( candidate_count <= 1 )); then
    if [[ "${layout_orientation}" == "portrait" ]]; then
      max_ratio="$(
        awk \
          -v height="${layout_display_h}" \
          -v top="${LAYOUT_TOP_PADDING}" \
          -v bottom="${layout_base_padding}" \
          'BEGIN { printf "%.3f", (height - top - bottom) / height }'
      )"
      adjust_saved_ratio \
        single_height_ratio \
        "${layout_single_height_ratio}" \
        0.30 \
        "${max_ratio}" \
        "${action}" \
        "${ratio_step}"
    elif (( layout_is_ultrawide == 1 )); then
      max_ratio="$(
        awk \
          -v width="${layout_display_w}" \
          -v padding="${layout_base_padding}" \
          'BEGIN { printf "%.3f", (width - (2 * padding)) / width }'
      )"
      adjust_saved_ratio \
        single_width_ratio \
        "${layout_single_width_ratio}" \
        0.30 \
        "${max_ratio}" \
        "${action}" \
        "${ratio_step}"
    fi
    return 0
  fi

  [[ "${layout_mode}" == "two-stack" ]] || return 0
  layout_is_valid_two_stack "${candidate_windows}" || return 0
  focused_region="$(
    layout_region_for_id "${candidate_windows}" "${window_id}"
  )"
  [[ -n "${focused_region}" ]] || return 0

  if [[ "${layout_orientation}" == "portrait" ]]; then
    ratio_key="vertical_split_ratio"
    current_ratio="${layout_portrait_split_ratio}"
  else
    ratio_key="horizontal_split_ratio"
    current_ratio="${layout_landscape_split_ratio}"
  fi

  case "${focused_region}:${action}" in
    first:grow|second:shrink)
      ratio_direction="grow"
      ;;
    first:shrink|second:grow)
      ratio_direction="shrink"
      ;;
    *)
      return 0
      ;;
  esac
  adjust_saved_ratio \
    "${ratio_key}" \
    "${current_ratio}" \
    0.10 \
    0.90 \
    "${ratio_direction}" \
    "${ratio_step}"
}

main "$@"
