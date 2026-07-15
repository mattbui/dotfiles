#!/usr/bin/env sh

# Resize the focused floating window, centered stack, or two-stack root split.
# Usage: resize.sh grow|shrink [multiplier]

step_ratio="0.025"
floating_step="80"
center_padding_step="80"

action="${1:-}"
multiplier="${2:-1}"
[ "$action" = grow ] || [ "$action" = shrink ] || exit 1
case "$multiplier" in
  ''|*[!0-9]*) exit 1 ;;
esac
[ "$multiplier" -ge 1 ] || exit 1

# shellcheck source=/dev/null
. "$(dirname "$0")/layout-lib.sh"

layout_require_commands || exit 0
step_ratio=$(awk "BEGIN { printf \"%.3f\", $step_ratio * $multiplier }")
floating_step=$((floating_step * multiplier))
center_padding_step=$((center_padding_step * multiplier))

window_json=$(yabai -m query --windows --window 2>/dev/null) || exit 0
[ -n "$window_json" ] || exit 0
is_floating=$(printf '%s' "$window_json" | jq -r '."is-floating"')

if [ "$is_floating" = true ]; then
  wx=$(printf '%s' "$window_json" | jq -r '.frame.x')
  wy=$(printf '%s' "$window_json" | jq -r '.frame.y')
  ww=$(printf '%s' "$window_json" | jq -r '.frame.w')
  wh=$(printf '%s' "$window_json" | jq -r '.frame.h')
  if [ "$action" = grow ]; then delta="$floating_step"; else delta="-$floating_step"; fi

  read -r nx ny nw nh <<EOF
$(awk "BEGIN {
  nw = $ww + $delta;
  nh = $wh + $delta;
  if (nw < 300) nw = 300;
  if (nh < 200) nh = 200;
  nx = $wx - ((nw - $ww) / 2);
  ny = $wy - ((nh - $wh) / 2);
  printf \"%d %d %d %d\", nx, ny, nw, nh;
}")
EOF

  yabai -m window --resize abs:"$nw":"$nh"
  yabai -m window --move abs:"$nx":"$ny"
  exit 0
fi

window_space=$(printf '%s' "$window_json" | jq -r '.space // empty')
[ -n "$window_space" ] || exit 0
layout_load_space "$window_space" || exit 0
layout_load_display || exit 0

if [ ! -f "$layout_state_file" ]; then
  "$layout_script_dir/apply-layout.sh" >/dev/null 2>&1
  window_json=$(yabai -m query --windows --window 2>/dev/null) || exit 0
fi

wide_layout=$(layout_read_preference)
candidate_windows=$(layout_query_candidates) || exit 0
candidate_count=$(layout_candidate_count "$candidate_windows")

if [ "$layout_is_wide" -eq 1 ] && { [ "$wide_layout" = center-stack ] || [ "$candidate_count" -le 1 ]; }; then
  ww=$(printf '%s' "$window_json" | jq -r '.frame.w')
  sp_top=$(layout_state_get "$layout_state_file" padding_top "")
  sp_bottom=$(layout_state_get "$layout_state_file" padding_bottom "")
  [ -n "$sp_top" ] || sp_top=$(yabai -m config --space "$layout_space_index" top_padding 2>/dev/null || printf '0')
  [ -n "$sp_bottom" ] || sp_bottom=$(yabai -m config --space "$layout_space_index" bottom_padding 2>/dev/null || printf '0')

  if [ "$action" = grow ]; then delta="-$center_padding_step"; else delta="$center_padding_step"; fi
  side=$(awk "BEGIN {
    side = (($layout_display_w - $ww) / 2) + $delta;
    min_side = $layout_display_w * 0.05;
    max_side = $layout_display_w * 0.35;
    if (side < min_side) side = min_side;
    if (side > max_side) side = max_side;
    printf \"%d\", side;
  }")

  yabai -m space "$layout_space_index" --padding abs:"$sp_top":"$sp_bottom":"$side":"$side" || exit 0
  solo_ratio=$(awk "BEGIN { printf \"%.3f\", 1 - (($side * 2) / $layout_display_w) }")
  layout_state_update "$layout_state_file" \
    solo_ratio "$solo_ratio" padding_top "$sp_top" padding_bottom "$sp_bottom" \
    padding_left "$side" padding_right "$side" 2>/dev/null
  exit 0
fi

[ "$layout_is_wide" -eq 1 ] && [ "$wide_layout" = two-stack ] || exit 0
layout_valid_two_stack "$candidate_windows" || exit 0

split_child=$(printf '%s' "$window_json" | jq -r '."split-child"')
case "$split_child:$action" in
  first_child:grow) delta="$step_ratio" ;;
  first_child:shrink) delta="-$step_ratio" ;;
  second_child:grow) delta="-$step_ratio" ;;
  second_child:shrink) delta="$step_ratio" ;;
  *) exit 0 ;;
esac

yabai -m window --ratio rel:"$delta" 2>/dev/null || exit 0
candidate_windows=$(layout_query_candidates) || exit 0
left_key=$(layout_left_region_key "$candidate_windows")
right_key=$(layout_right_region_key "$candidate_windows")
left_id=$(layout_visible_id_in_frame "$candidate_windows" "$left_key")
right_id=$(layout_visible_id_in_frame "$candidate_windows" "$right_key")
[ -n "$left_id" ] && [ -n "$right_id" ] || exit 0

left_w=$(printf '%s' "$candidate_windows" | jq -r --argjson id "$left_id" '.[] | select(.id == $id) | .frame.w')
right_w=$(printf '%s' "$candidate_windows" | jq -r --argjson id "$right_id" '.[] | select(.id == $id) | .frame.w')
new_ratio=$(awk "BEGIN { sum=$left_w+$right_w; if (sum <= 0) exit 1; printf \"%.3f\", $left_w / sum }") || exit 0
new_ratio=$(clamp_ratio "$new_ratio")
layout_state_update "$layout_state_file" split_ratio "$new_ratio" 2>/dev/null
