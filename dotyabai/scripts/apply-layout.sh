#!/usr/bin/env sh

# Reconcile the current space with the flexible layout.
# Usage: apply-layout.sh [reset|check|dry-run]

action="${1:-apply}"
case "$action" in
  apply|reset|check|dry-run) ;;
  --reset|force|--force) action="reset" ;;
  *) exit 1 ;;
esac

# shellcheck source=/dev/null
. "$(dirname "$0")/layout-lib.sh"

layout_require_commands || exit 0
layout_load_space || exit 0
layout_load_display || exit 0
layout_load_preferences

if [ "$action" = reset ]; then
  [ -n "$layout_state_file" ] || exit 0
  single_width_ratio="$layout_default_single_width_ratio"
  single_height_ratio="$layout_default_single_height_ratio"
  horizontal_split_ratio="$layout_default_horizontal_split_ratio"
  vertical_split_ratio="$layout_default_vertical_split_ratio"
fi

candidate_windows=$(layout_query_candidates) || exit 0
candidate_count=$(layout_candidate_count "$candidate_windows")
region_count=$(layout_region_count "$candidate_windows")
layout_single_sizing

if [ "$selected_layout" = single-stack ]; then
  effective_arrangement="single-stack"
  desired_space_type="stack"
elif [ "$candidate_count" -le 1 ]; then
  effective_arrangement="temporary-single-stack"
  desired_space_type="bsp"
else
  effective_arrangement="two-stack"
  desired_space_type="bsp"
  layout_padding_top="$layout_top_padding"
  layout_padding_bottom="$layout_base_padding"
  layout_padding_left="$layout_base_padding"
  layout_padding_right="$layout_base_padding"
fi

layout_current_config() {
  yabai -m config --space "$layout_space_index" "$1" 2>/dev/null || printf ''
}

layout_padding_compliant() {
  [ "$(layout_current_config window_gap)" = "$layout_gap" ] &&
    [ "$(layout_current_config top_padding)" = "$layout_padding_top" ] &&
    [ "$(layout_current_config bottom_padding)" = "$layout_padding_bottom" ] &&
    [ "$(layout_current_config left_padding)" = "$layout_padding_left" ] &&
    [ "$(layout_current_config right_padding)" = "$layout_padding_right" ]
}

layout_two_stack_ratio_compliant() {
  first_key=$(layout_first_region_key "$candidate_windows")
  second_key=$(layout_second_region_key "$candidate_windows")
  first_id=$(layout_visible_id_in_frame "$candidate_windows" "$first_key")
  second_id=$(layout_visible_id_in_frame "$candidate_windows" "$second_key")
  [ -n "$first_id" ] && [ -n "$second_id" ] || return 1
  first_size=$(layout_frame_size_for_id "$candidate_windows" "$first_id")
  second_size=$(layout_frame_size_for_id "$candidate_windows" "$second_id")
  desired_ratio=$(layout_active_split_ratio)
  awk "BEGIN {
    sum=$first_size+$second_size;
    if (sum <= 0) exit 1;
    d=($first_size/sum)-$desired_ratio;
    if (d < 0) d=-d;
    exit !(d <= $layout_ratio_tolerance)
  }"
}

layout_evaluate() {
  compliant=false
  [ "$layout_space_type" = "$desired_space_type" ] || return 1

  case "$effective_arrangement" in
    single-stack)
      [ "$region_count" -le 1 ] && layout_padding_compliant && compliant=true
      ;;
    temporary-single-stack)
      [ "$region_count" -le 1 ] &&
        [ "$(layout_current_config split_type)" = "$layout_split_type" ] &&
        layout_padding_compliant &&
        compliant=true
      ;;
    two-stack)
      layout_valid_two_stack "$candidate_windows" &&
        [ "$(layout_current_config split_type)" = "$layout_split_type" ] &&
        layout_padding_compliant &&
        layout_two_stack_ratio_compliant &&
        compliant=true
      ;;
  esac
  [ "$compliant" = true ]
}

layout_window_summary() {
  if [ "$effective_arrangement" = two-stack ] && layout_valid_two_stack "$candidate_windows"; then
    first_key=$(layout_first_region_key "$candidate_windows")
    second_key=$(layout_second_region_key "$candidate_windows")
    first_count=$(layout_candidate_count "$(layout_windows_in_frame "$candidate_windows" "$first_key")")
    second_count=$(layout_candidate_count "$(layout_windows_in_frame "$candidate_windows" "$second_key")")
    printf '%s: %s · %s: %s' \
      "$layout_first_name" "$first_count" "$layout_second_name" "$second_count"
  else
    printf 'Tiled: %s' "$candidate_count"
  fi
}

layout_active_ratio() {
  case "$effective_arrangement" in
    two-stack) layout_active_split_ratio ;;
    single-stack|temporary-single-stack) printf '%s' "$layout_effective_single_ratio" ;;
  esac
}

layout_print_machine_summary() {
  printf 'space=%s label=%s display=%s area_class=%s orientation=%s selected=%s arrangement=%s tree=%s windows=%s regions=%s ratio=%s padding=%s,%s,%s,%s gap=%s compliant=%s\n' \
    "$layout_space_index" "${layout_space_label:-none}" "$layout_space_display" \
    "$layout_area_class" "$layout_orientation" "$selected_layout" \
    "$effective_arrangement" "$layout_space_type" "$candidate_count" \
    "$region_count" "$(layout_active_ratio)" "$layout_padding_top" \
    "$layout_padding_bottom" "$layout_padding_left" "$layout_padding_right" \
    "$layout_gap" "$compliant"
}

layout_notify_check() {
  command -v osascript >/dev/null 2>&1 || return 0
  osascript \
    -e 'on run argv' \
    -e 'display notification (item 1 of argv) with title "yabai" subtitle (item 2 of argv)' \
    -e 'end run' \
    "$1" "$2" >/dev/null 2>&1
}

layout_report_check() {
  if [ "$compliant" = true ]; then
    status_label="Layout OK"
    notification_status="✓ Ready"
  else
    status_label="Repair needed"
    notification_status="⚠ Repair with ⌥R"
  fi
  window_summary=$(layout_window_summary)
  active_ratio=$(layout_active_ratio)
  ratio_summary=""
  [ -n "$active_ratio" ] && ratio_summary=" · Ratio $active_ratio"
  printf 'Space: %s (%s) · Display %s\nArea: %s · Orientation: %s\nLayout: %s · Arrangement: %s · Tree: %s\nWindows: %s\nPadding: %s/%s/%s/%s · Gap: %s%s\nStatus: %s\n' \
    "${layout_space_label:-unlabeled}" "$layout_space_index" "$layout_space_display" \
    "$layout_area_class" "$layout_orientation" "$selected_layout" \
    "$effective_arrangement" "$layout_space_type" "$window_summary" \
    "$layout_padding_top" "$layout_padding_bottom" "$layout_padding_left" \
    "$layout_padding_right" "$layout_gap" "$ratio_summary" "$status_label"
  layout_notify_check "$window_summary$ratio_summary · $notification_status" \
    "Space: ${layout_space_label:-$layout_space_index} · $selected_layout"
}

if [ "$action" = check ]; then
  layout_evaluate
  check_status=$?
  layout_report_check
  exit "$check_status"
elif [ "$action" = dry-run ]; then
  if layout_evaluate; then
    layout_print_machine_summary
    printf '%s\n' 'action=none'
  else
    layout_print_machine_summary
    printf '%s\n' 'action=reconcile'
  fi
  exit 0
fi

mkdir -p "$layout_state_root" 2>/dev/null || exit 0
lock_dir="$layout_state_root/layout.lock"
pending_file="$layout_state_root/layout.pending"
if ! mkdir "$lock_dir" 2>/dev/null; then
  : >"$pending_file" 2>/dev/null
  exit 0
fi

release_layout_lock() {
  status=$?
  trap - EXIT INT TERM
  rmdir "$lock_dir" 2>/dev/null
  if [ -f "$pending_file" ]; then
    rm -f "$pending_file" 2>/dev/null
    "$0" >/dev/null 2>&1 &
  fi
  exit "$status"
}
trap release_layout_lock EXIT INT TERM

layout_extract_visible_second() {
  windows="$1"
  preferred_id=$(layout_preferred_visible_id "$windows")
  [ -n "$preferred_id" ] || return 1
  anchor_id=$(layout_stable_id_except "$windows" "$preferred_id")
  [ -n "$anchor_id" ] || return 1

  yabai -m window "$anchor_id" --insert "$layout_extract_direction" 2>/dev/null || return 1
  yabai -m window "$preferred_id" --toggle float 2>/dev/null || return 1
  if ! yabai -m query --windows --window "$preferred_id" 2>/dev/null |
    jq -e '."is-floating" == true' >/dev/null 2>&1; then
    yabai -m window "$anchor_id" --insert "$layout_extract_direction" >/dev/null 2>&1 || :
    return 1
  fi

  if ! yabai -m window "$preferred_id" --toggle float 2>/dev/null; then
    yabai -m window "$preferred_id" --toggle float >/dev/null 2>&1 || return 1
  fi
  if yabai -m query --windows --window "$preferred_id" 2>/dev/null |
    jq -e '."is-floating" == true' >/dev/null 2>&1; then
    yabai -m window "$preferred_id" --toggle float >/dev/null 2>&1 || return 1
  fi
  if yabai -m query --windows --window "$preferred_id" 2>/dev/null |
    jq -e '."is-floating" == true' >/dev/null 2>&1; then
    return 1
  fi

  updated_windows=$(layout_query_candidates) || return 1
  preferred_region=$(layout_region_for_id "$updated_windows" "$preferred_id")
  if [ "$preferred_region" = first ]; then
    yabai -m window "$preferred_id" --swap "$layout_extract_direction" 2>/dev/null || return 1
  fi
}

layout_stack_extra_regions_into_first() {
  windows="$1"
  second_key=$(layout_second_region_key "$windows")
  anchor_id=$(layout_anchor_id_excluding_frame "$windows" "$second_key")
  [ -n "$anchor_id" ] || return 1
  anchor_key=$(layout_frame_key_for_id "$windows" "$anchor_id")
  stack_ids=$(layout_ids_outside_frames "$windows" "$anchor_key" "$second_key")
  if [ -n "$stack_ids" ]; then
    for id in $stack_ids; do
      yabai -m window "$anchor_id" --stack "$id" 2>/dev/null || return 1
    done
  fi
}

layout_reconcile_two_stack() {
  windows="$1"
  regions=$(layout_region_count "$windows")
  axis_regions=$(layout_axis_region_count "$windows")
  other_regions=$(layout_other_axis_region_count "$windows")

  # Repair any extra leaves on the old axis first, then toggle the root split.
  # This keeps the old first/second memberships mapped to the new orientation.
  if [ "$axis_regions" -eq 1 ] && [ "$other_regions" -ge 2 ]; then
    desired_axis="$layout_axis"
    if [ "$layout_axis" = x ]; then layout_axis="y"; else layout_axis="x"; fi
    layout_stack_extra_regions_into_first "$windows" || return 1
    layout_axis="$desired_axis"
    windows=$(layout_query_candidates) || return 1
    regions=$(layout_region_count "$windows")
    axis_regions=$(layout_axis_region_count "$windows")
    other_regions=$(layout_other_axis_region_count "$windows")
    [ "$regions" -eq 2 ] && [ "$axis_regions" -eq 1 ] && [ "$other_regions" -eq 2 ] || return 1
    toggle_id=$(layout_preferred_visible_id "$windows")
    [ -n "$toggle_id" ] || return 1
    yabai -m window "$toggle_id" --toggle split 2>/dev/null || return 1
    windows=$(layout_query_candidates) || return 1
    layout_valid_two_stack "$windows" && return 0
    regions=$(layout_region_count "$windows")
    axis_regions=$(layout_axis_region_count "$windows")
  fi

  if [ "$regions" -eq 1 ] || [ "$axis_regions" -lt 2 ]; then
    layout_extract_visible_second "$windows" || return 1
    return 0
  fi
  if [ "$regions" -eq 2 ] && [ "$axis_regions" -eq 2 ]; then
    return 0
  fi

  layout_stack_extra_regions_into_first "$windows"
}

if [ "$effective_arrangement" = single-stack ]; then
  layout_apply_space_settings stack "$layout_gap" \
    "$layout_padding_top" "$layout_padding_bottom" \
    "$layout_padding_left" "$layout_padding_right" || exit 0
  layout_save_preferences 2>/dev/null
  exit 0
fi

layout_apply_config_if_needed split_type "$layout_split_type" || exit 0
active_split_ratio=$(layout_active_split_ratio)
yabai -m config split_ratio "$active_split_ratio" || exit 0

if [ "$effective_arrangement" = temporary-single-stack ]; then
  layout_apply_space_settings bsp "$layout_gap" \
    "$layout_padding_top" "$layout_padding_bottom" \
    "$layout_padding_left" "$layout_padding_right" || exit 0
  layout_save_preferences 2>/dev/null
  exit 0
fi

layout_apply_space_settings bsp "$layout_gap" \
  "$layout_top_padding" "$layout_base_padding" \
  "$layout_base_padding" "$layout_base_padding" || exit 0

candidate_windows=$(layout_query_candidates) || exit 0
layout_reconcile_two_stack "$candidate_windows" || exit 0
candidate_windows=$(layout_query_candidates) || exit 0
layout_valid_two_stack "$candidate_windows" || exit 0

second_key=$(layout_second_region_key "$candidate_windows")
second_id=$(layout_visible_id_in_frame "$candidate_windows" "$second_key")
first_key=$(layout_first_region_key "$candidate_windows")
first_id=$(layout_visible_id_in_frame "$candidate_windows" "$first_key")
[ -n "$first_id" ] && [ -n "$second_id" ] || exit 0
first_size=$(layout_frame_size_for_id "$candidate_windows" "$first_id")
second_size=$(layout_frame_size_for_id "$candidate_windows" "$second_id")
if ! awk "BEGIN {
  sum=$first_size+$second_size;
  if (sum <= 0) exit 1;
  d=($first_size/sum)-$active_split_ratio;
  if (d < 0) d=-d;
  exit !(d <= $layout_ratio_tolerance)
}"; then
  yabai -m window "$second_id" --ratio abs:"$active_split_ratio" 2>/dev/null || exit 0
fi

layout_save_preferences 2>/dev/null
