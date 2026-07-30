#!/usr/bin/env bash

# Shared, source-only helpers for the flexible-layout scripts.
# Functions consume layout_* context that callers assign explicitly.
# shellcheck disable=SC2034,SC2154

LAYOUT_SCRIPT_DIR="$(
  cd -- "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null &&
    pwd
)"
readonly LAYOUT_SCRIPT_DIR
LAYOUT_STATE_ROOT="${YABAI_LAYOUT_STATE_DIR:-}"
if [[ -z "${LAYOUT_STATE_ROOT}" ]]; then
  LAYOUT_STATE_ROOT="${YABAI_STATE_DIR:-${HOME}/.local/state/yabai}"
fi
readonly LAYOUT_STATE_ROOT

# shellcheck source=layout-state.sh
. "${LAYOUT_SCRIPT_DIR}/layout-state.sh"
# shellcheck source=ignore-list.sh
. "${LAYOUT_SCRIPT_DIR}/ignore-list.sh"

readonly LAYOUT_AREA_THRESHOLD="3500000"
readonly LAYOUT_ULTRAWIDE_THRESHOLD="2.0"
readonly LAYOUT_DEFAULT_SINGLE_WIDTH_RATIO="0.65"
readonly LAYOUT_DEFAULT_SINGLE_HEIGHT_RATIO="0.90"
readonly LAYOUT_DEFAULT_LANDSCAPE_SPLIT_RATIO="0.50"
readonly LAYOUT_DEFAULT_PORTRAIT_SPLIT_RATIO="0.50"
readonly LAYOUT_RATIO_TOLERANCE="0.01"
readonly LAYOUT_TOP_PADDING="6"
readonly LAYOUT_COMPACT_PADDING="8"
readonly LAYOUT_ROOMY_PADDING="12"
readonly LAYOUT_COMPACT_GAP="8"
readonly LAYOUT_ROOMY_GAP="10"

layout_require() {
  command -v "$1" >/dev/null 2>&1 || return 1
}

layout_require_commands() {
  layout_require yabai &&
    layout_require jq &&
    layout_require awk
}

# Queries one yabai space and writes its JSON to stdout.
layout_query_space() {
  local selector="${1:-}"

  if [[ -n "${selector}" ]]; then
    yabai -m query --spaces --space "${selector}" 2>/dev/null
  else
    yabai -m query --spaces --space 2>/dev/null
  fi
}

# Resolves the state-file path for a canonical space-N label.
layout_state_file_for_label() {
  local label="$1"

  if [[ "${label}" =~ ^space-[1-9][0-9]*$ ]]; then
    layout_state_file_for_space_label "${label}"
  fi
}

# Queries one yabai display and writes its JSON to stdout.
layout_query_display() {
  yabai -m query --displays --display "$1" 2>/dev/null
}

# Resolves the display profile and writes it as JSON.
layout_resolve_display_profile() {
  local width="$1"
  local height="$2"
  local area_class
  local base_padding
  local gap
  local orientation
  local axis
  local split_type
  local extract_direction
  local first_region_name
  local second_region_name
  local is_ultrawide

  if awk \
    -v width="${width}" \
    -v height="${height}" \
    -v threshold="${LAYOUT_AREA_THRESHOLD}" \
    'BEGIN { exit !((width * height) >= threshold) }'; then
    area_class="roomy"
    base_padding="${LAYOUT_ROOMY_PADDING}"
    gap="${LAYOUT_ROOMY_GAP}"
  else
    area_class="compact"
    base_padding="${LAYOUT_COMPACT_PADDING}"
    gap="${LAYOUT_COMPACT_GAP}"
  fi

  if awk \
    -v width="${width}" \
    -v height="${height}" \
    'BEGIN { exit !(height > width) }'; then
    orientation="portrait"
    axis="y"
    split_type="horizontal"
    extract_direction="south"
    first_region_name="Top"
    second_region_name="Bottom"
  else
    orientation="landscape"
    axis="x"
    split_type="vertical"
    extract_direction="east"
    first_region_name="Left"
    second_region_name="Right"
  fi

  is_ultrawide="$(
    awk \
      -v width="${width}" \
      -v height="${height}" \
      -v threshold="${LAYOUT_ULTRAWIDE_THRESHOLD}" \
      'BEGIN { print ((width / height) >= threshold) ? 1 : 0 }'
  )"

  jq -cn \
    --arg area_class "${area_class}" \
    --arg base_padding "${base_padding}" \
    --arg gap "${gap}" \
    --arg orientation "${orientation}" \
    --arg axis "${axis}" \
    --arg split_type "${split_type}" \
    --arg extract_direction "${extract_direction}" \
    --arg first_region_name "${first_region_name}" \
    --arg second_region_name "${second_region_name}" \
    --arg is_ultrawide "${is_ultrawide}" '
      {
        area_class: $area_class,
        base_padding: $base_padding,
        gap: $gap,
        orientation: $orientation,
        axis: $axis,
        split_type: $split_type,
        extract_direction: $extract_direction,
        first_region_name: $first_region_name,
        second_region_name: $second_region_name,
        is_ultrawide: $is_ultrawide
      }
    '
}

layout_default_mode() {
  if [[ "$1" == "roomy" ]]; then
    printf 'two-stack'
  else
    printf 'single-stack'
  fi
}

# Reads and normalizes the saved preferences, writing them as JSON.
layout_resolve_preferences() {
  local state_file="$1"
  local area_class="$2"
  local state_json
  local default_mode

  state_json="$(layout_state_read "${state_file}")" || return 1
  default_mode="$(layout_default_mode "${area_class}")"

  jq -cn \
    --argjson state "${state_json}" \
    --arg area_class "${area_class}" \
    --arg default_mode "${default_mode}" \
    --argjson default_single_width "${LAYOUT_DEFAULT_SINGLE_WIDTH_RATIO}" \
    --argjson default_single_height "${LAYOUT_DEFAULT_SINGLE_HEIGHT_RATIO}" \
    --argjson default_landscape "${LAYOUT_DEFAULT_LANDSCAPE_SPLIT_RATIO}" \
    --argjson default_portrait "${LAYOUT_DEFAULT_PORTRAIT_SPLIT_RATIO}" '
      def valid_ratio($value; $minimum; $maximum; $inclusive):
        ($value | tostring) as $text
        | (
            if ($text | test("^[0-9]+([.][0-9]+)?$"))
            then ($text | tonumber)
            else null
            end
          ) as $number
        | if (
            $number != null
            and $number >= $minimum
            and (
              if $inclusive
              then $number <= $maximum
              else $number < $maximum
              end
            )
          )
          then $number
          else null
          end;

      ($state.last_area_class // "" | tostring) as $stored_area
      | (
          if $stored_area == "compact" or $stored_area == "roomy"
          then $stored_area
          else ""
          end
        ) as $last_area_class
      | ($state.selected_layout // "" | tostring) as $stored_mode
      | (
          if $stored_mode == "single-stack"
            or $stored_mode == "two-stack"
          then $stored_mode
          else $default_mode
          end
        ) as $valid_mode
      | {
          mode: (
            if (
              $last_area_class != ""
              and $last_area_class != $area_class
            )
            then $default_mode
            else $valid_mode
            end
          ),
          last_area_class: $last_area_class,
          single_width_ratio: (
            valid_ratio($state.single_width_ratio; 0.30; 1.0; false)
            // $default_single_width
          ),
          single_height_ratio: (
            valid_ratio($state.single_height_ratio; 0.30; 1.0; false)
            // $default_single_height
          ),
          landscape_split_ratio: (
            valid_ratio($state.horizontal_split_ratio; 0.10; 0.90; true)
            // $default_landscape
          ),
          portrait_split_ratio: (
            valid_ratio($state.vertical_split_ratio; 0.10; 0.90; true)
            // $default_portrait
          )
        }
    '
}

layout_save_preferences() {
  local single_width_ratio
  local single_height_ratio
  local landscape_split_ratio
  local portrait_split_ratio

  [[ -n "${layout_state_file}" ]] || return 0
  single_width_ratio="$(
    awk -v ratio="${layout_single_width_ratio}" \
      'BEGIN { printf "%.3f", ratio }'
  )"
  single_height_ratio="$(
    awk -v ratio="${layout_single_height_ratio}" \
      'BEGIN { printf "%.3f", ratio }'
  )"
  landscape_split_ratio="$(
    awk -v ratio="${layout_landscape_split_ratio}" \
      'BEGIN { printf "%.3f", ratio }'
  )"
  portrait_split_ratio="$(
    awk -v ratio="${layout_portrait_split_ratio}" \
      'BEGIN { printf "%.3f", ratio }'
  )"

  layout_state_update "${layout_state_file}" \
    selected_layout "${layout_mode}" \
    last_area_class "${layout_area_class}" \
    single_width_ratio "${single_width_ratio}" \
    single_height_ratio "${single_height_ratio}" \
    horizontal_split_ratio "${landscape_split_ratio}" \
    vertical_split_ratio "${portrait_split_ratio}"
}

layout_query_candidate_windows() {
  local ignored_apps_json

  if [[ -f "${IGNORE_FILE}" ]]; then
    ignored_apps_json="$(
      sed '/^[[:space:]]*$/d' "${IGNORE_FILE}" |
        jq -R . |
        jq -s .
    )" || return 1
  else
    ignored_apps_json="$(
      printf '%s\n' "${IGNORE_DEFAULTS}" |
        sed '/^[[:space:]]*$/d' |
        jq -R . |
        jq -s .
    )" || return 1
  fi
  yabai -m query --windows --space "${layout_space_index}" 2>/dev/null |
    jq --argjson ignored_apps "${ignored_apps_json}" '
      [
        .[]
        | .app as $app
        | select(."is-floating" == false)
        | select(."is-minimized" == false)
        | select(."is-hidden" == false)
        | select(($ignored_apps | index($app)) == null)
      ]
    '
}

layout_candidate_count() {
  jq 'length' <<<"$1"
}

layout_region_count() {
  jq '
    [
      .[]
      | [.frame.x, .frame.y, .frame.w, .frame.h]
    ]
    | unique
    | length
  ' <<<"$1"
}

layout_axis_region_count() {
  jq \
    --arg axis "${layout_axis}" \
    '[.[] | .frame[$axis]] | unique | length' \
    <<<"$1"
}

layout_cross_axis_region_count() {
  local cross_axis="y"

  [[ "${layout_axis}" == "y" ]] && cross_axis="x"
  jq \
    --arg axis "${cross_axis}" \
    '[.[] | .frame[$axis]] | unique | length' \
    <<<"$1"
}

layout_region_bounds_for_id() {
  jq -r --argjson id "$2" '
    .[]
    | select(.id == $id)
    | [.frame.x, .frame.y, .frame.w, .frame.h]
    | map(tostring)
    | join(":")
  ' <<<"$1"
}

layout_first_region_bounds() {
  jq -r --arg axis "${layout_axis}" '
    sort_by(.frame[$axis], .id)
    | first
    | [.frame.x, .frame.y, .frame.w, .frame.h]
    | map(tostring)
    | join(":")
  ' <<<"$1"
}

layout_second_region_bounds() {
  jq -r --arg axis "${layout_axis}" '
    sort_by(.frame[$axis], .id)
    | last
    | [.frame.x, .frame.y, .frame.w, .frame.h]
    | map(tostring)
    | join(":")
  ' <<<"$1"
}

layout_preferred_window_id() {
  jq -r --arg axis "${layout_axis}" '
    ([.[] | select(."has-focus" == true)] | first.id)
    // (
      [.[] | select(."is-visible" == true)]
      | sort_by(.frame[$axis], .id)
      | last.id
    )
    // (sort_by(.frame[$axis], .id) | last.id)
    // empty
  ' <<<"$1"
}

layout_window_id_in_region() {
  jq -r --arg bounds "$2" '
    [
      .[]
      | select(
          (
            [.frame.x, .frame.y, .frame.w, .frame.h]
            | map(tostring)
            | join(":")
          ) == $bounds
        )
    ]
    | (
        ([.[] | select(."has-focus" == true)] | first.id)
        // ([.[] | select(."is-visible" == true)] | first.id)
        // (sort_by(.id) | last.id)
        // empty
      )
  ' <<<"$1"
}

layout_windows_in_region() {
  jq --arg bounds "$2" '
    [
      .[]
      | select(
          (
            [.frame.x, .frame.y, .frame.w, .frame.h]
            | map(tostring)
            | join(":")
          ) == $bounds
        )
    ]
  ' <<<"$1"
}

layout_replacement_id() {
  jq -r --argjson anchor "$2" '
    [.[] | select(.id != $anchor)]
    | sort_by([
        (
          if ."has-focus" == true or ."is-visible" == true
          then 1
          else 0
          end
        ),
        .id
      ])
    | first.id // empty
  ' <<<"$1"
}

layout_anchor_id_outside_region() {
  jq \
    -r \
    --arg excluded_bounds "$2" \
    --arg axis "${layout_axis}" '
      [
        .[]
        | select(
            (
              [.frame.x, .frame.y, .frame.w, .frame.h]
              | map(tostring)
              | join(":")
            ) != $excluded_bounds
          )
      ]
      | sort_by([
          (if ."stack-index" > 0 then 0 else 1 end),
          .frame[$axis],
          .id
        ])
      | first.id // empty
    ' <<<"$1"
}

layout_window_ids_outside_regions() {
  jq \
    -r \
    --arg first_region_bounds "$2" \
    --arg second_region_bounds "$3" '
    [
      .[]
      | . + {
          region_bounds: (
            [.frame.x, .frame.y, .frame.w, .frame.h]
            | map(tostring)
            | join(":")
          )
      }
      | select(
          .region_bounds != $first_region_bounds
          and .region_bounds != $second_region_bounds
        )
    ]
    | sort_by([
        (
          if ."has-focus" == true then 2
          elif ."is-visible" == true then 1
          else 0
          end
        ),
        .id
      ])
    | .[].id
  ' <<<"$1"
}

layout_stable_id_except() {
  jq -r --argjson excluded "$2" '
    [.[] | select(.id != $excluded)]
    | sort_by(.id)
    | first.id // empty
  ' <<<"$1"
}

layout_region_for_id() {
  local windows="$1"
  local window_id="$2"
  local first_region_bounds
  local second_region_bounds
  local window_region_bounds

  first_region_bounds="$(layout_first_region_bounds "${windows}")"
  second_region_bounds="$(layout_second_region_bounds "${windows}")"
  window_region_bounds="$(layout_region_bounds_for_id "${windows}" "${window_id}")"
  if [[ "${window_region_bounds}" == "${first_region_bounds}" ]]; then
    printf 'first'
  elif [[ "${window_region_bounds}" == "${second_region_bounds}" ]]; then
    printf 'second'
  fi
}

layout_apply_config_if_needed() {
  local config_key="$1"
  local desired_value="$2"
  local current_value

  current_value="$(
    yabai -m config --space "${layout_space_index}" "${config_key}" 2>/dev/null ||
      printf ''
  )"
  [[ "${current_value}" == "${desired_value}" ]] ||
    yabai -m config \
      --space "${layout_space_index}" \
      "${config_key}" \
      "${desired_value}"
}

layout_set_space_layout() {
  local desired_layout="$1"

  if [[ "${layout_space_type}" != "${desired_layout}" ]]; then
    yabai -m space \
      "${layout_space_index}" \
      --layout "${desired_layout}" || return 1
    layout_space_type="${desired_layout}"
  fi
}

layout_apply_space_settings() {
  local space_layout="$1"
  local gap="$2"
  local top_padding="$3"
  local bottom_padding="$4"
  local left_padding="$5"
  local right_padding="$6"

  layout_set_space_layout "${space_layout}" || return 1
  layout_apply_config_if_needed window_gap "${gap}" || return 1
  layout_apply_config_if_needed top_padding "${top_padding}" || return 1
  layout_apply_config_if_needed bottom_padding "${bottom_padding}" || return 1
  layout_apply_config_if_needed left_padding "${left_padding}" || return 1
  layout_apply_config_if_needed right_padding "${right_padding}" || return 1
}

layout_is_valid_two_stack() {
  local windows="$1"

  (( $(layout_candidate_count "${windows}") >= 2 )) &&
    (( $(layout_region_count "${windows}") == 2 )) &&
    (( $(layout_axis_region_count "${windows}") == 2 ))
}

# Resolves single-stack sizing and writes it as JSON.
layout_resolve_single_stack_sizing() {
  local orientation="$1"
  local display_width="$2"
  local display_height="$3"
  local base_padding="$4"
  local is_ultrawide="$5"
  local single_width_ratio="$6"
  local single_height_ratio="$7"
  local max_ratio
  local effective_ratio=""
  local effective_ratio_raw
  local side_padding
  local padding_top="${LAYOUT_TOP_PADDING}"
  local padding_bottom="${base_padding}"
  local padding_left="${base_padding}"
  local padding_right="${base_padding}"

  if [[ "${orientation}" == "portrait" ]]; then
    max_ratio="$(
      awk \
        -v height="${display_height}" \
        -v top="${LAYOUT_TOP_PADDING}" \
        -v bottom="${base_padding}" \
        'BEGIN { printf "%.9f", (height - top - bottom) / height }'
    )"
    effective_ratio_raw="$(
      awk \
        -v ratio="${single_height_ratio}" \
        -v maximum="${max_ratio}" '
          BEGIN {
            if (ratio > maximum) {
              ratio = maximum
            }
            printf "%.9f", ratio
          }
        '
    )"
    effective_ratio="$(
      awk -v ratio="${effective_ratio_raw}" 'BEGIN { printf "%.3f", ratio }'
    )"
    read -r padding_top padding_bottom < <(
      awk \
        -v height="${display_height}" \
        -v ratio="${effective_ratio_raw}" \
        -v minimum_top="${LAYOUT_TOP_PADDING}" \
        -v minimum_bottom="${base_padding}" '
          BEGIN {
            budget = height * (1 - ratio)
            top = int((budget / 2) + 0.5)
            bottom = int((budget - top) + 0.5)
            if (top < minimum_top) {
              top = minimum_top
              bottom = int((budget - top) + 0.5)
            }
            if (bottom < minimum_bottom) {
              bottom = minimum_bottom
              top = int((budget - bottom) + 0.5)
            }
            printf "%d %d\n", top, bottom
          }
        '
    )
  elif (( is_ultrawide == 1 )); then
    max_ratio="$(
      awk \
        -v width="${display_width}" \
        -v padding="${base_padding}" \
        'BEGIN { printf "%.9f", (width - (2 * padding)) / width }'
    )"
    effective_ratio_raw="$(
      awk \
        -v ratio="${single_width_ratio}" \
        -v maximum="${max_ratio}" '
          BEGIN {
            if (ratio > maximum) {
              ratio = maximum
            }
            printf "%.9f", ratio
          }
        '
    )"
    effective_ratio="$(
      awk -v ratio="${effective_ratio_raw}" 'BEGIN { printf "%.3f", ratio }'
    )"
    side_padding="$(
      awk \
        -v width="${display_width}" \
        -v ratio="${effective_ratio_raw}" \
        -v minimum="${base_padding}" '
          BEGIN {
            padding = int(((width * (1 - ratio)) / 2) + 0.5)
            if (padding < minimum) {
              padding = minimum
            }
            printf "%d", padding
          }
        '
    )"
    padding_left="${side_padding}"
    padding_right="${side_padding}"
  fi

  jq -cn \
    --arg effective_ratio "${effective_ratio}" \
    --arg padding_top "${padding_top}" \
    --arg padding_bottom "${padding_bottom}" \
    --arg padding_left "${padding_left}" \
    --arg padding_right "${padding_right}" '
      {
        effective_ratio: $effective_ratio,
        padding_top: $padding_top,
        padding_bottom: $padding_bottom,
        padding_left: $padding_left,
        padding_right: $padding_right
      }
    '
}

layout_split_ratio_for_orientation() {
  if [[ "${layout_orientation}" == "portrait" ]]; then
    printf '%s' "${layout_portrait_split_ratio}"
  else
    printf '%s' "${layout_landscape_split_ratio}"
  fi
}

layout_axis_size_for_id() {
  local size_key="w"

  [[ "${layout_axis}" == "y" ]] && size_key="h"
  jq \
    -r \
    --argjson id "$2" \
    --arg size "${size_key}" \
    '.[] | select(.id == $id) | .frame[$size]' \
    <<<"$1"
}

# Resolves the effective arrangement and writes its settings as JSON.
layout_resolve_arrangement() {
  local mode="$1"
  local candidate_count="$2"
  local base_padding="$3"
  local padding_top="$4"
  local padding_bottom="$5"
  local padding_left="$6"
  local padding_right="$7"
  local arrangement
  local desired_space_type

  if [[ "${mode}" == "single-stack" ]]; then
    arrangement="single-stack"
    desired_space_type="stack"
  elif (( candidate_count <= 1 )); then
    arrangement="temporary-single-stack"
    desired_space_type="bsp"
  else
    arrangement="two-stack"
    desired_space_type="bsp"
    padding_top="${LAYOUT_TOP_PADDING}"
    padding_bottom="${base_padding}"
    padding_left="${base_padding}"
    padding_right="${base_padding}"
  fi

  jq -cn \
    --arg arrangement "${arrangement}" \
    --arg desired_space_type "${desired_space_type}" \
    --arg padding_top "${padding_top}" \
    --arg padding_bottom "${padding_bottom}" \
    --arg padding_left "${padding_left}" \
    --arg padding_right "${padding_right}" '
      {
        arrangement: $arrangement,
        desired_space_type: $desired_space_type,
        padding_top: $padding_top,
        padding_bottom: $padding_bottom,
        padding_left: $padding_left,
        padding_right: $padding_right
      }
    '
}

layout_current_space_config() {
  yabai -m config --space "${layout_space_index}" "$1" 2>/dev/null ||
    printf ''
}

layout_spacing_is_compliant() {
  [[ "$(layout_current_space_config window_gap)" == "${layout_gap}" ]] &&
    [[ "$(layout_current_space_config top_padding)" == "${layout_padding_top}" ]] &&
    [[ "$(layout_current_space_config bottom_padding)" == "${layout_padding_bottom}" ]] &&
    [[ "$(layout_current_space_config left_padding)" == "${layout_padding_left}" ]] &&
    [[ "$(layout_current_space_config right_padding)" == "${layout_padding_right}" ]]
}

layout_ratio_is_compliant() {
  local first_region_size="$1"
  local second_region_size="$2"
  local desired_ratio="$3"

  awk \
    -v first_region_size="${first_region_size}" \
    -v second_region_size="${second_region_size}" \
    -v desired="${desired_ratio}" \
    -v tolerance="${LAYOUT_RATIO_TOLERANCE}" '
      BEGIN {
        total_region_size = first_region_size + second_region_size
        if (total_region_size <= 0) {
          exit 1
        }
        difference = (first_region_size / total_region_size) - desired
        if (difference < 0) {
          difference = -difference
        }
        exit !(difference <= tolerance)
      }
    '
}

layout_ratio_values_match() {
  local current_ratio="$1"
  local desired_ratio="$2"

  awk \
    -v current="${current_ratio}" \
    -v desired="${desired_ratio}" \
    'BEGIN { exit !(current == desired) }'
}

layout_two_stack_ratio_is_compliant() {
  local windows="$1"
  local first_region_bounds
  local second_region_bounds
  local first_region_window_id
  local second_region_window_id
  local first_region_size
  local second_region_size
  local desired_ratio

  first_region_bounds="$(layout_first_region_bounds "${windows}")"
  second_region_bounds="$(layout_second_region_bounds "${windows}")"
  first_region_window_id="$(
    layout_window_id_in_region "${windows}" "${first_region_bounds}"
  )"
  second_region_window_id="$(
    layout_window_id_in_region "${windows}" "${second_region_bounds}"
  )"
  [[ -n "${first_region_window_id}" ]] || return 1
  [[ -n "${second_region_window_id}" ]] || return 1

  first_region_size="$(
    layout_axis_size_for_id "${windows}" "${first_region_window_id}"
  )"
  second_region_size="$(
    layout_axis_size_for_id "${windows}" "${second_region_window_id}"
  )"
  desired_ratio="$(layout_split_ratio_for_orientation)"
  layout_ratio_is_compliant \
    "${first_region_size}" \
    "${second_region_size}" \
    "${desired_ratio}"
}

layout_is_compliant() {
  local arrangement="$1"
  local desired_space_type="$2"
  local windows="$3"
  local region_count="$4"

  [[ "${layout_space_type}" == "${desired_space_type}" ]] || return 1

  case "${arrangement}" in
    single-stack)
      (( region_count <= 1 )) && layout_spacing_is_compliant
      ;;
    temporary-single-stack)
      (( region_count <= 1 )) &&
        [[ "$(layout_current_space_config split_type)" == "${layout_split_type}" ]] &&
        layout_spacing_is_compliant
      ;;
    two-stack)
      layout_is_valid_two_stack "${windows}" &&
        [[ "$(layout_current_space_config split_type)" == "${layout_split_type}" ]] &&
        layout_spacing_is_compliant &&
        layout_two_stack_ratio_is_compliant "${windows}"
      ;;
    *)
      return 1
      ;;
  esac
}

layout_ratio_for_arrangement() {
  case "$1" in
    two-stack)
      layout_split_ratio_for_orientation
      ;;
    single-stack|temporary-single-stack)
      printf '%s' "${layout_effective_single_ratio}"
      ;;
  esac
}
