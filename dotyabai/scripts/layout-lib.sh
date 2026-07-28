#!/usr/bin/env sh

# Shared, source-only helpers for the flexible-layout scripts.

layout_script_dir=$(CDPATH='' cd -- "$(dirname "$0")" 2>/dev/null && pwd)
layout_state_root="${YABAI_LAYOUT_STATE_DIR:-${YABAI_STATE_DIR:-$HOME/.local/state/yabai}}"
state_dir="$layout_state_root"

# shellcheck source=/dev/null
. "$layout_script_dir/layout-state.sh"
# shellcheck source=/dev/null
. "$layout_script_dir/ignore-list.sh"

layout_area_threshold="3500000"
layout_ultrawide_threshold="2.0"
layout_default_single_width_ratio="0.65"
layout_default_single_height_ratio="0.90"
layout_default_horizontal_split_ratio="0.50"
layout_default_vertical_split_ratio="0.50"
layout_ratio_tolerance="0.01"
layout_top_padding="6"
layout_compact_padding="8"
layout_roomy_padding="12"
layout_compact_gap="8"
layout_roomy_gap="10"

layout_require() {
  command -v "$1" >/dev/null 2>&1 || return 1
}

layout_require_commands() {
  layout_require yabai &&
    layout_require jq &&
    layout_require awk
}

layout_load_space() {
  selector="${1:-}"

  if [ -n "$selector" ]; then
    layout_space_json=$(yabai -m query --spaces --space "$selector" 2>/dev/null) || return 1
  else
    layout_space_json=$(yabai -m query --spaces --space 2>/dev/null) || return 1
  fi

  layout_space_index=$(printf '%s' "$layout_space_json" | jq -r '.index // empty')
  layout_space_label=$(printf '%s' "$layout_space_json" | jq -r '.label // empty')
  layout_space_type=$(printf '%s' "$layout_space_json" | jq -r '.type // empty')
  layout_space_display=$(printf '%s' "$layout_space_json" | jq -r '.display // empty')
  [ -n "$layout_space_index" ] && [ -n "$layout_space_display" ] || return 1

  layout_state_file=""
  label_number=${layout_space_label#space-}
  case "$layout_space_label:$label_number" in
    space-*:[1-9]*)
      case "$label_number" in
        *[!0-9]*) return 0 ;;
      esac
      layout_state_file=$(layout_state_file_for_space_label "$layout_space_label")
      ;;
  esac
}

layout_load_display() {
  display_selector="${1:-$layout_space_display}"
  layout_display_json=$(yabai -m query --displays --display "$display_selector" 2>/dev/null) || return 1
  layout_display_w=$(printf '%s' "$layout_display_json" | jq -r '.frame.w // empty')
  layout_display_h=$(printf '%s' "$layout_display_json" | jq -r '.frame.h // empty')
  [ -n "$layout_display_w" ] && [ -n "$layout_display_h" ] || return 1

  if awk "BEGIN { exit !(($layout_display_w * $layout_display_h) >= $layout_area_threshold) }"; then
    layout_area_class="roomy"
    layout_base_padding="$layout_roomy_padding"
    layout_gap="$layout_roomy_gap"
  else
    layout_area_class="compact"
    layout_base_padding="$layout_compact_padding"
    layout_gap="$layout_compact_gap"
  fi

  if awk "BEGIN { exit !($layout_display_h > $layout_display_w) }"; then
    layout_orientation="portrait"
    layout_axis="y"
    layout_split_type="horizontal"
    layout_extract_direction="south"
    layout_first_name="Top"
    layout_second_name="Bottom"
  else
    layout_orientation="landscape"
    layout_axis="x"
    layout_split_type="vertical"
    layout_extract_direction="east"
    layout_first_name="Left"
    layout_second_name="Right"
  fi

  layout_is_ultrawide=$(awk "BEGIN { print (($layout_display_w / $layout_display_h) >= $layout_ultrawide_threshold) ? 1 : 0 }")
}

layout_default_selection() {
  if [ "$layout_area_class" = roomy ]; then
    printf 'two-stack'
  else
    printf 'single-stack'
  fi
}

layout_valid_selection() {
  [ "$1" = single-stack ] || [ "$1" = two-stack ]
}

layout_valid_single_ratio() {
  awk -v v="$1" 'BEGIN {
    if (v !~ /^[0-9]+([.][0-9]+)?$/) exit 1
    exit !(v >= 0.30 && v < 1.0)
  }' 2>/dev/null
}

layout_valid_split_ratio() {
  awk -v v="$1" 'BEGIN {
    if (v !~ /^[0-9]+([.][0-9]+)?$/) exit 1
    exit !(v >= 0.10 && v <= 0.90)
  }' 2>/dev/null
}

layout_state_value() {
  key="$1"
  default="$2"
  if [ -n "$layout_state_file" ]; then
    layout_state_get "$layout_state_file" "$key" "$default"
  else
    printf '%s' "$default"
  fi
}

layout_load_preferences() {
  default_selection=$(layout_default_selection)
  selected_layout=$(layout_state_value selected_layout "$default_selection")
  layout_valid_selection "$selected_layout" || selected_layout="$default_selection"

  last_area_class=$(layout_state_value last_area_class "")
  case "$last_area_class" in
    compact|roomy) ;;
    *) last_area_class="" ;;
  esac
  if [ -n "$last_area_class" ] && [ "$last_area_class" != "$layout_area_class" ]; then
    selected_layout="$default_selection"
  fi

  single_width_ratio=$(layout_state_value single_width_ratio "$layout_default_single_width_ratio")
  layout_valid_single_ratio "$single_width_ratio" || single_width_ratio="$layout_default_single_width_ratio"
  single_height_ratio=$(layout_state_value single_height_ratio "$layout_default_single_height_ratio")
  layout_valid_single_ratio "$single_height_ratio" || single_height_ratio="$layout_default_single_height_ratio"
  horizontal_split_ratio=$(layout_state_value horizontal_split_ratio "$layout_default_horizontal_split_ratio")
  layout_valid_split_ratio "$horizontal_split_ratio" || horizontal_split_ratio="$layout_default_horizontal_split_ratio"
  vertical_split_ratio=$(layout_state_value vertical_split_ratio "$layout_default_vertical_split_ratio")
  layout_valid_split_ratio "$vertical_split_ratio" || vertical_split_ratio="$layout_default_vertical_split_ratio"
}

layout_save_preferences() {
  [ -n "$layout_state_file" ] || return 0
  layout_state_update "$layout_state_file" \
    selected_layout "$selected_layout" \
    last_area_class "$layout_area_class" \
    single_width_ratio "$(awk "BEGIN { printf \"%.3f\", $single_width_ratio }")" \
    single_height_ratio "$(awk "BEGIN { printf \"%.3f\", $single_height_ratio }")" \
    horizontal_split_ratio "$(awk "BEGIN { printf \"%.3f\", $horizontal_split_ratio }")" \
    vertical_split_ratio "$(awk "BEGIN { printf \"%.3f\", $vertical_split_ratio }")"
}

layout_query_candidates() {
  if [ -f "$ignore_file" ]; then
    ignored_apps_json=$(sed '/^[[:space:]]*$/d' "$ignore_file" | jq -R . | jq -s .) || return 1
  else
    ignored_apps_json=$(printf '%s\n' "$ignore_defaults" | sed '/^[[:space:]]*$/d' | jq -R . | jq -s .) || return 1
  fi
  yabai -m query --windows --space "$layout_space_index" 2>/dev/null |
    jq --argjson ignored_apps "$ignored_apps_json" '[.[] | .app as $app | select(."is-floating" == false and ."is-minimized" == false and ."is-hidden" == false and (($ignored_apps | index($app)) | not))]'
}

layout_candidate_count() {
  printf '%s' "$1" | jq 'length'
}

layout_region_count() {
  printf '%s' "$1" | jq '[.[] | [.frame.x, .frame.y, .frame.w, .frame.h]] | unique | length'
}

layout_axis_region_count() {
  printf '%s' "$1" | jq --arg axis "$layout_axis" '[.[] | .frame[$axis]] | unique | length'
}

layout_other_axis_region_count() {
  other_axis="y"
  [ "$layout_axis" = y ] && other_axis="x"
  printf '%s' "$1" | jq --arg axis "$other_axis" '[.[] | .frame[$axis]] | unique | length'
}

layout_frame_key_for_id() {
  printf '%s' "$1" |
    jq -r --argjson id "$2" '.[] | select(.id == $id) | [.frame.x, .frame.y, .frame.w, .frame.h] | map(tostring) | join(":")'
}

layout_first_region_key() {
  printf '%s' "$1" |
    jq -r --arg axis "$layout_axis" 'sort_by(.frame[$axis], .id) | first | [.frame.x, .frame.y, .frame.w, .frame.h] | map(tostring) | join(":")'
}

layout_second_region_key() {
  printf '%s' "$1" |
    jq -r --arg axis "$layout_axis" 'sort_by(.frame[$axis], .id) | last | [.frame.x, .frame.y, .frame.w, .frame.h] | map(tostring) | join(":")'
}

layout_preferred_visible_id() {
  printf '%s' "$1" |
    jq -r --arg axis "$layout_axis" '([.[] | select(."has-focus" == true)] | first.id) //
      ([.[] | select(."is-visible" == true)] | sort_by(.frame[$axis], .id) | last.id) //
      (sort_by(.frame[$axis], .id) | last.id) // empty'
}

layout_visible_id_in_frame() {
  printf '%s' "$1" |
    jq -r --arg key "$2" '
      [.[] | select(([.frame.x, .frame.y, .frame.w, .frame.h] | map(tostring) | join(":")) == $key)] |
      (([.[] | select(."has-focus" == true)] | first.id) //
       ([.[] | select(."is-visible" == true)] | first.id) //
       (sort_by(.id) | last.id) // empty)'
}

layout_windows_in_frame() {
  printf '%s' "$1" |
    jq --arg key "$2" '[.[] | select(([.frame.x, .frame.y, .frame.w, .frame.h] | map(tostring) | join(":")) == $key)]'
}

layout_replacement_id() {
  printf '%s' "$1" |
    jq -r --argjson anchor "$2" '[.[] | select(.id != $anchor)] |
      sort_by([(if ."has-focus" == true or ."is-visible" == true then 1 else 0 end), .id]) |
      first.id // empty'
}

layout_anchor_id_excluding_frame() {
  printf '%s' "$1" |
    jq -r --arg excluded "$2" --arg axis "$layout_axis" '
      [.[] | select(([.frame.x, .frame.y, .frame.w, .frame.h] | map(tostring) | join(":")) != $excluded)] |
      sort_by([(if ."stack-index" > 0 then 0 else 1 end), .frame[$axis], .id]) |
      first.id // empty'
}

layout_ids_outside_frames() {
  printf '%s' "$1" |
    jq -r --arg keep_a "$2" --arg keep_b "$3" '
      [.[] | . + {frame_key: ([.frame.x, .frame.y, .frame.w, .frame.h] | map(tostring) | join(":"))} |
       select(.frame_key != $keep_a and .frame_key != $keep_b)] |
      sort_by([(if ."has-focus" == true then 2 elif ."is-visible" == true then 1 else 0 end), .id]) |
      .[].id'
}

layout_stable_id_except() {
  printf '%s' "$1" |
    jq -r --argjson excluded "$2" '[.[] | select(.id != $excluded)] | sort_by(.id) | first.id // empty'
}

layout_region_for_id() {
  windows="$1"
  window_id="$2"
  first_key=$(layout_first_region_key "$windows")
  second_key=$(layout_second_region_key "$windows")
  window_key=$(layout_frame_key_for_id "$windows" "$window_id")
  if [ "$window_key" = "$first_key" ]; then
    printf 'first'
  elif [ "$window_key" = "$second_key" ]; then
    printf 'second'
  fi
}

layout_apply_config_if_needed() {
  key="$1"
  desired="$2"
  current=$(yabai -m config --space "$layout_space_index" "$key" 2>/dev/null || printf '')
  [ "$current" = "$desired" ] || yabai -m config --space "$layout_space_index" "$key" "$desired"
}

layout_set_space_layout() {
  desired="$1"
  if [ "$layout_space_type" != "$desired" ]; then
    yabai -m space "$layout_space_index" --layout "$desired" || return 1
    layout_space_type="$desired"
  fi
}

layout_apply_space_settings() {
  space_layout="$1"
  gap="$2"
  top="$3"
  bottom="$4"
  left="$5"
  right="$6"
  layout_set_space_layout "$space_layout" || return 1
  layout_apply_config_if_needed window_gap "$gap" || return 1
  layout_apply_config_if_needed top_padding "$top" || return 1
  layout_apply_config_if_needed bottom_padding "$bottom" || return 1
  layout_apply_config_if_needed left_padding "$left" || return 1
  layout_apply_config_if_needed right_padding "$right" || return 1
}

layout_valid_two_stack() {
  windows="$1"
  [ "$(layout_candidate_count "$windows")" -ge 2 ] &&
    [ "$(layout_region_count "$windows")" -eq 2 ] &&
    [ "$(layout_axis_region_count "$windows")" -eq 2 ]
}

layout_single_sizing() {
  layout_effective_single_ratio=""
  layout_padding_top="$layout_top_padding"
  layout_padding_bottom="$layout_base_padding"
  layout_padding_left="$layout_base_padding"
  layout_padding_right="$layout_base_padding"

  if [ "$layout_orientation" = portrait ]; then
    max_ratio=$(awk "BEGIN { printf \"%.9f\", ($layout_display_h - $layout_top_padding - $layout_base_padding) / $layout_display_h }")
    effective_ratio=$(awk "BEGIN { v=$single_height_ratio; m=$max_ratio; if (v > m) v=m; printf \"%.9f\", v }")
    layout_effective_single_ratio=$(awk "BEGIN { printf \"%.3f\", $effective_ratio }")
    read -r layout_padding_top layout_padding_bottom <<EOF
$(awk "BEGIN {
  budget=$layout_display_h * (1 - $effective_ratio);
  top=int((budget / 2) + 0.5); bottom=int((budget - top) + 0.5);
  if (top < $layout_top_padding) { top=$layout_top_padding; bottom=int((budget-top)+0.5) }
  if (bottom < $layout_base_padding) { bottom=$layout_base_padding; top=int((budget-bottom)+0.5) }
  printf \"%d %d\", top, bottom
}")
EOF
  elif [ "$layout_is_ultrawide" -eq 1 ]; then
    max_ratio=$(awk "BEGIN { printf \"%.9f\", ($layout_display_w - 2 * $layout_base_padding) / $layout_display_w }")
    effective_ratio=$(awk "BEGIN { v=$single_width_ratio; m=$max_ratio; if (v > m) v=m; printf \"%.9f\", v }")
    layout_effective_single_ratio=$(awk "BEGIN { printf \"%.3f\", $effective_ratio }")
    side_padding=$(awk "BEGIN { p=int(($layout_display_w * (1 - $effective_ratio) / 2)+0.5); if (p < $layout_base_padding) p=$layout_base_padding; printf \"%d\", p }")
    layout_padding_left="$side_padding"
    layout_padding_right="$side_padding"
  fi
}

layout_active_split_ratio() {
  if [ "$layout_orientation" = portrait ]; then
    printf '%s' "$vertical_split_ratio"
  else
    printf '%s' "$horizontal_split_ratio"
  fi
}

layout_frame_size_for_id() {
  size_key="w"
  [ "$layout_axis" = y ] && size_key="h"
  printf '%s' "$1" | jq -r --argjson id "$2" --arg size "$size_key" '.[] | select(.id == $id) | .frame[$size]'
}
