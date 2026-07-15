#!/usr/bin/env sh

# Reconcile the current space with the display-aware layout.
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

candidate_windows=$(layout_query_candidates) || exit 0
candidate_count=$(layout_candidate_count "$candidate_windows")
region_count=$(layout_region_count "$candidate_windows")
wide_layout=$(layout_read_preference)

saved_solo_ratio=$(layout_state_get "$layout_state_file" solo_ratio "$layout_wide_solo_ratio")
if [ "$action" = "reset" ] || ! valid_ratio "$saved_solo_ratio"; then
  saved_solo_ratio="$layout_wide_solo_ratio"
fi

saved_split_ratio=$(layout_state_get "$layout_state_file" split_ratio "$layout_wide_split_ratio")
if [ "$action" = "reset" ] || ! valid_ratio "$saved_split_ratio"; then
  saved_split_ratio="$layout_wide_split_ratio"
fi

layout_evaluate() {
  if [ "$layout_is_wide" -eq 0 ]; then
    desired_mode="normal"
  elif [ "$candidate_count" -le 1 ]; then
    desired_mode="wide-solo"
  elif [ "$wide_layout" = "center-stack" ]; then
    desired_mode="wide-center-stack"
  else
    desired_mode="wide-two-stack"
  fi

  compliant=false
  case "$desired_mode" in
    normal)
      [ "$layout_space_type" = "stack" ] && compliant=true
      ;;
    wide-solo|wide-center-stack)
      [ "$layout_space_type" = "bsp" ] && [ "$region_count" -le 1 ] && compliant=true
      ;;
    wide-two-stack)
      layout_valid_two_stack "$candidate_windows" && compliant=true
      ;;
  esac

  [ "$compliant" = true ]
}

layout_print_machine_summary() {
  printf 'space=%s display=%s desired=%s preference=%s windows=%s regions=%s compliant=%s\n' \
    "$layout_space_index" "$layout_space_display" "$desired_mode" "$wide_layout" \
    "$candidate_count" "$region_count" "$compliant"
}

layout_mode_label() {
  case "$desired_mode" in
    normal) printf 'Normal stack' ;;
    wide-solo) printf 'Centered solo' ;;
    wide-center-stack) printf 'Centered stack' ;;
    wide-two-stack) printf 'Two stacks' ;;
  esac
}

layout_status_space_label() {
  if [ -n "$layout_space_label" ]; then
    printf '%s (%s)' "$layout_space_label" "$layout_space_index"
  else
    printf '%s' "$layout_space_index"
  fi
}

layout_window_summary() {
  if [ "$desired_mode" = "wide-two-stack" ] && layout_valid_two_stack "$candidate_windows"; then
    left_key=$(layout_left_region_key "$candidate_windows")
    right_key=$(layout_right_region_key "$candidate_windows")
    left_count=$(layout_candidate_count "$(layout_windows_in_frame "$candidate_windows" "$left_key")")
    right_count=$(layout_candidate_count "$(layout_windows_in_frame "$candidate_windows" "$right_key")")
    printf 'Left: %s · Right: %s' "$left_count" "$right_count"
  else
    printf 'Tiled: %s' "$candidate_count"
  fi
}

layout_active_ratio() {
  case "$desired_mode" in
    wide-two-stack) printf '%s' "$saved_split_ratio" ;;
    wide-solo|wide-center-stack) printf '%s' "$saved_solo_ratio" ;;
  esac
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
  mode_label=$(layout_mode_label)
  space_label=$(layout_status_space_label)
  window_summary=$(layout_window_summary)
  active_ratio=$(layout_active_ratio)

  if [ "$compliant" = true ]; then
    status_label="Layout OK"
    notification_status="$status_label"
  else
    status_label="Repair needed"
    notification_status="$status_label · try ⌥R"
  fi

  if [ -n "$active_ratio" ]; then
    report=$(printf 'Space: %s · Display %s\nLayout: %s · Tree %s · Preference %s\nWindows: %s\nRatio: %s\nStatus: %s' \
      "$space_label" "$layout_space_display" "$mode_label" "$layout_space_type" \
      "$wide_layout" "$window_summary" "$active_ratio" "$status_label")
    notification_message="$window_summary · Ratio: $active_ratio · $notification_status"
  else
    report=$(printf 'Space: %s · Display %s\nLayout: %s · Tree %s · Preference %s\nWindows: %s\nStatus: %s' \
      "$space_label" "$layout_space_display" "$mode_label" "$layout_space_type" \
      "$wide_layout" "$window_summary" "$status_label")
    notification_message="$window_summary · $notification_status"
  fi

  notification_space="${layout_space_label:-$layout_space_index}"
  printf '%s\n' "$report"
  layout_notify_check "$notification_message" "Space: $notification_space · $mode_label"
}

if [ "$action" = "check" ]; then
  layout_evaluate
  check_status=$?
  layout_report_check
  exit "$check_status"
elif [ "$action" = "dry-run" ]; then
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

layout_save_state() {
  mode="$1"
  side_left="$2"
  side_right="$3"
  saved_solo_ratio="$4"
  saved_split_ratio="$5"

  layout_state_update "$layout_state_file" \
    mode "$mode" \
    wide_layout "$wide_layout" \
    solo_ratio "$saved_solo_ratio" \
    split_ratio "$saved_split_ratio" \
    gap "$layout_wide_gap" \
    padding_top "$layout_wide_top_padding" \
    padding_bottom "$layout_wide_padding" \
    padding_left "$side_left" \
    padding_right "$side_right" \
    window_placement first_child \
    window_insertion_point first 2>/dev/null
}

layout_collapse_to_center() {
  windows="$1"
  preferred_id=$(layout_preferred_visible_id "$windows")
  [ -n "$preferred_id" ] || return 1

  anchor_id=$(layout_stable_id_except "$windows" "$preferred_id")
  [ -n "$anchor_id" ] || return 0

  stack_ids=$(layout_ids_except "$windows" "$anchor_id" "$preferred_id")
  if [ -n "$stack_ids" ]; then
    for id in $stack_ids; do
      yabai -m window "$anchor_id" --stack "$id" 2>/dev/null || return 1
    done
  fi

  if [ "$preferred_id" != "$anchor_id" ]; then
    yabai -m window "$anchor_id" --stack "$preferred_id" 2>/dev/null || return 1
  fi
}

layout_extract_visible_right() {
  windows="$1"
  preferred_id=$(layout_preferred_visible_id "$windows")
  [ -n "$preferred_id" ] || return 1

  anchor_id=$(layout_stable_id_except "$windows" "$preferred_id")
  [ -n "$anchor_id" ] || return 1

  # The insertion marker belongs to the root leaf, not only to anchor_id. When
  # preferred_id is temporarily floated out, yabai transfers the marker to the
  # surviving stack member. Re-tiling preferred_id then creates it directly as
  # the right child and consumes the marker.
  yabai -m window "$anchor_id" --insert east 2>/dev/null || return 1
  yabai -m window "$preferred_id" --toggle float 2>/dev/null || return 1
  if ! yabai -m query --windows --window "$preferred_id" 2>/dev/null |
    jq -e '."is-floating" == true' >/dev/null 2>&1; then
    # The window did not leave the stack, so clear the unused insertion marker.
    yabai -m window "$anchor_id" --insert east >/dev/null 2>&1 || :
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

  # A pre-existing manual east marker would have made --insert east toggle it
  # off. Verify the result and correct the side without retaining marker state.
  updated_windows=$(layout_query_candidates) || return 1
  preferred_side=$(layout_side_for_id "$updated_windows" "$preferred_id")
  if [ "$preferred_side" = left ]; then
    yabai -m window "$preferred_id" --swap east 2>/dev/null || return 1
  fi
}

layout_reconcile_two_stack() {
  windows="$1"
  regions=$(layout_region_count "$windows")
  x_regions=$(layout_distinct_x_count "$windows")

  if [ "$regions" -eq 1 ] || [ "$x_regions" -lt 2 ]; then
    layout_extract_visible_right "$windows" || return 1
    return 0
  fi

  if [ "$regions" -eq 2 ] && [ "$x_regions" -eq 2 ]; then
    return 0
  fi

  right_key=$(layout_right_region_key "$windows")
  anchor_id=$(layout_anchor_id_excluding_frame "$windows" "$right_key")
  [ -n "$anchor_id" ] || return 1
  anchor_key=$(layout_frame_key_for_id "$windows" "$anchor_id")

  stack_ids=$(layout_ids_outside_frames "$windows" "$anchor_key" "$right_key")
  if [ -n "$stack_ids" ]; then
    for id in $stack_ids; do
      yabai -m window "$anchor_id" --stack "$id" 2>/dev/null || return 1
    done
  fi

  return 0
}

if [ "$layout_is_wide" -eq 0 ]; then
  layout_apply_space_settings stack second_child focused \
    "$layout_normal_gap" "$layout_normal_top_padding" \
    "$layout_normal_padding" "$layout_normal_padding" \
    "$layout_normal_padding" || exit 0

  layout_state_update "$layout_state_file" \
    mode normal \
    wide_layout "$wide_layout" \
    solo_ratio "$saved_solo_ratio" \
    split_ratio "$saved_split_ratio" \
    gap "$layout_normal_gap" \
    padding_top "$layout_normal_top_padding" \
    padding_bottom "$layout_normal_padding" \
    padding_left "$layout_normal_padding" \
    padding_right "$layout_normal_padding" \
    window_placement second_child \
    window_insertion_point focused 2>/dev/null
  exit 0
fi

# These values are global in yabai even when config is called with --space.
# Set them before any structural operation so arrivals naturally appear in the
# first leaf as its first child.
layout_apply_config_if_needed window_placement first_child || exit 0
layout_apply_config_if_needed window_insertion_point first || exit 0
yabai -m config --space "$layout_space_index" split_type vertical || exit 0
yabai -m config split_ratio "$saved_split_ratio" || exit 0

if [ "$candidate_count" -le 1 ]; then
  side_padding=$(layout_side_padding "$saved_solo_ratio")
  layout_apply_space_settings bsp first_child first \
    "$layout_wide_gap" "$layout_wide_top_padding" \
    "$layout_wide_padding" "$side_padding" "$side_padding" || exit 0
  layout_save_state wide-solo "$side_padding" "$side_padding" \
    "$saved_solo_ratio" "$saved_split_ratio"
  exit 0
fi

if [ "$wide_layout" = "center-stack" ]; then
  layout_collapse_to_center "$candidate_windows" || exit 0
  side_padding=$(layout_side_padding "$saved_solo_ratio")
  layout_apply_space_settings bsp first_child first \
    "$layout_wide_gap" "$layout_wide_top_padding" \
    "$layout_wide_padding" "$side_padding" "$side_padding" || exit 0
  layout_save_state wide-center-stack "$side_padding" "$side_padding" \
    "$saved_solo_ratio" "$saved_split_ratio"
  exit 0
fi

layout_apply_space_settings bsp first_child first \
  "$layout_wide_gap" "$layout_wide_top_padding" \
  "$layout_wide_padding" "$layout_wide_padding" \
  "$layout_wide_padding" || exit 0

candidate_windows=$(layout_query_candidates) || exit 0
layout_reconcile_two_stack "$candidate_windows" || exit 0
candidate_windows=$(layout_query_candidates) || exit 0
layout_valid_two_stack "$candidate_windows" || exit 0

right_key=$(layout_right_region_key "$candidate_windows")
right_id=$(layout_visible_id_in_frame "$candidate_windows" "$right_key")
[ -n "$right_id" ] || exit 0

left_key=$(layout_left_region_key "$candidate_windows")
left_id=$(layout_visible_id_in_frame "$candidate_windows" "$left_key")
[ -n "$left_id" ] || exit 0

left_w=$(printf '%s' "$candidate_windows" | jq -r --argjson id "$left_id" '.[] | select(.id == $id) | .frame.w')
right_w=$(printf '%s' "$candidate_windows" | jq -r --argjson id "$right_id" '.[] | select(.id == $id) | .frame.w')

if ! awk "BEGIN { sum = $left_w + $right_w; if (sum <= 0) exit 1; d = ($left_w / sum) - $saved_split_ratio; if (d < 0) d = -d; exit !(d <= $layout_ratio_tolerance) }"; then
  yabai -m window "$right_id" --ratio abs:"$saved_split_ratio" 2>/dev/null || exit 0
fi

layout_save_state wide-two-stack "$layout_wide_padding" \
  "$layout_wide_padding" "$saved_solo_ratio" "$saved_split_ratio"
