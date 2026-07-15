#!/usr/bin/env sh

# Shared, source-only helpers for the wide-layout scripts.

layout_script_dir=$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)
layout_state_root="${YABAI_STATE_DIR:-$HOME/.local/state/yabai}"
state_dir="$layout_state_root"

# shellcheck source=/dev/null
. "$layout_script_dir/layout-state.sh"
# shellcheck source=/dev/null
. "$layout_script_dir/ignore-list.sh"

layout_wide_threshold="2.0"
layout_wide_solo_ratio="0.65"
layout_wide_split_ratio="0.5"
layout_ratio_tolerance="0.01"
layout_wide_top_padding="6"
layout_wide_padding="12"
layout_wide_gap="10"
layout_normal_top_padding="6"
layout_normal_padding="8"
layout_normal_gap="8"

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
  layout_space_id=$(printf '%s' "$layout_space_json" | jq -r '.id // empty')
  layout_space_label=$(printf '%s' "$layout_space_json" | jq -r '.label // empty')
  layout_space_type=$(printf '%s' "$layout_space_json" | jq -r '.type // empty')
  layout_space_display=$(printf '%s' "$layout_space_json" | jq -r '.display // empty')

  [ -n "$layout_space_index" ] && [ -n "$layout_space_display" ] || return 1

  if [ -n "$layout_space_label" ]; then
    layout_state_file=$(layout_state_file_for_space_label "$layout_space_label")
  else
    layout_state_file=$(layout_state_file_for_space_label "id-$layout_space_id")
  fi
}

layout_load_display() {
  display_selector="${1:-$layout_space_display}"
  layout_display_json=$(yabai -m query --displays --display "$display_selector" 2>/dev/null) || return 1
  layout_display_w=$(printf '%s' "$layout_display_json" | jq -r '.frame.w // empty')
  layout_display_h=$(printf '%s' "$layout_display_json" | jq -r '.frame.h // empty')
  [ -n "$layout_display_w" ] && [ -n "$layout_display_h" ] || return 1

  layout_is_wide=$(awk "BEGIN { print (($layout_display_w / $layout_display_h) >= $layout_wide_threshold) ? 1 : 0 }")
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
  printf '%s' "$1" |
    jq '[.[] | [.frame.x, .frame.y, .frame.w, .frame.h]] | unique | length'
}

layout_distinct_x_count() {
  printf '%s' "$1" | jq '[.[].frame.x] | unique | length'
}

layout_frame_key_for_id() {
  printf '%s' "$1" |
    jq -r --argjson id "$2" '.[] | select(.id == $id) | [.frame.x, .frame.y, .frame.w, .frame.h] | map(tostring) | join(":")'
}

layout_right_region_key() {
  printf '%s' "$1" |
    jq -r 'sort_by(.frame.x, .frame.y, .id) | last | [.frame.x, .frame.y, .frame.w, .frame.h] | map(tostring) | join(":")'
}

layout_left_region_key() {
  printf '%s' "$1" |
    jq -r 'sort_by(.frame.x, .frame.y, .id) | first | [.frame.x, .frame.y, .frame.w, .frame.h] | map(tostring) | join(":")'
}

layout_preferred_visible_id() {
  # Tiled focus wins. Otherwise prefer the visible right member, then the
  # visible left member, without changing focus away from a floating window.
  printf '%s' "$1" |
    jq -r '([.[] | select(."has-focus" == true)] | first.id) //
           ([.[] | select(."is-visible" == true)] | sort_by(.frame.x, .id) | last.id) //
           (sort_by(.frame.x, .id) | last.id) // empty'
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
    jq -r --argjson anchor "$2" '
      [.[] | select(.id != $anchor)] |
      sort_by([(if ."has-focus" == true or ."is-visible" == true then 1 else 0 end), .id]) |
      first.id // empty'
}

layout_anchor_id_excluding_frame() {
  # Prefer an existing stack as the anchor. This prevents a newly inserted,
  # unstacked leftmost leaf from replacing the established left stack.
  printf '%s' "$1" |
    jq -r --arg excluded "$2" '
      [.[] | select(([.frame.x, .frame.y, .frame.w, .frame.h] | map(tostring) | join(":")) != $excluded)] |
      sort_by([(if ."stack-index" > 0 then 0 else 1 end), .frame.x, .id]) |
      first.id // empty'
}

layout_ids_outside_frames() {
  printf '%s' "$1" |
    jq -r --arg keep_a "$2" --arg keep_b "$3" '
      [.[] |
       . + {frame_key: ([.frame.x, .frame.y, .frame.w, .frame.h] | map(tostring) | join(":"))} |
       select(.frame_key != $keep_a and .frame_key != $keep_b)] |
      sort_by([(if ."has-focus" == true then 2 elif ."is-visible" == true then 1 else 0 end), .id]) |
      .[].id'
}

layout_ids_except() {
  printf '%s' "$1" |
    jq -r --argjson first "$2" --argjson last "$3" '
      [.[] | select(.id != $first and .id != $last)] |
      sort_by([(if ."has-focus" == true then 2 elif ."is-visible" == true then 1 else 0 end), .id]) |
      .[].id'
}

layout_stable_id_except() {
  printf '%s' "$1" |
    jq -r --argjson excluded "$2" '[.[] | select(.id != $excluded)] | sort_by(.id) | first.id // empty'
}

layout_side_for_id() {
  windows="$1"
  window_id="$2"
  left_key=$(layout_left_region_key "$windows")
  right_key=$(layout_right_region_key "$windows")
  window_key=$(layout_frame_key_for_id "$windows" "$window_id")

  if [ "$window_key" = "$left_key" ]; then
    printf 'left'
  elif [ "$window_key" = "$right_key" ]; then
    printf 'right'
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
  placement="$2"
  insertion_point="$3"
  gap="$4"
  top="$5"
  bottom="$6"
  left="$7"
  right="$8"

  layout_set_space_layout "$space_layout" || return 1
  layout_apply_config_if_needed window_placement "$placement" || return 1
  layout_apply_config_if_needed window_insertion_point "$insertion_point" || return 1
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
    [ "$(layout_distinct_x_count "$windows")" -eq 2 ]
}

layout_read_preference() {
  preference=$(layout_state_get "$layout_state_file" wide_layout "two-stack")
  case "$preference" in
    two-stack|center-stack) printf '%s' "$preference" ;;
    *) printf 'two-stack' ;;
  esac
}

layout_side_padding() {
  ratio="$1"
  awk "BEGIN { printf \"%d\", ($layout_display_w * (1 - $ratio) / 2) }"
}
