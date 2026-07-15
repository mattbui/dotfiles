#!/usr/bin/env sh

# Move the focused tiled window to a side in wide two-stack mode.
# Usage: move-to-stack.sh left|right

target_side="${1:-}"
case "$target_side" in
  left|right) ;;
  *) exit 1 ;;
esac

# shellcheck source=/dev/null
. "$(dirname "$0")/layout-lib.sh"

layout_require_commands || exit 0
layout_load_space || exit 0
layout_load_display || exit 0
[ "$layout_is_wide" -eq 1 ] || exit 0
[ "$(layout_read_preference)" = "two-stack" ] || exit 0

window_json=$(yabai -m query --windows --window 2>/dev/null) || exit 0
window_id=$(printf '%s' "$window_json" | jq -r '.id // empty')
is_floating=$(printf '%s' "$window_json" | jq -r '."is-floating"')
is_minimized=$(printf '%s' "$window_json" | jq -r '."is-minimized"')
[ -n "$window_id" ] && [ "$is_floating" = false ] && [ "$is_minimized" = false ] || exit 0

# Repair a collapsed or manually altered tree before interpreting its sides.
"$layout_script_dir/apply-layout.sh" || exit 0
candidate_windows=$(layout_query_candidates) || exit 0
layout_valid_two_stack "$candidate_windows" || exit 0

current_side=$(layout_side_for_id "$candidate_windows" "$window_id")
[ -n "$current_side" ] || exit 0
[ "$current_side" != "$target_side" ] || exit 0

left_key=$(layout_left_region_key "$candidate_windows")
right_key=$(layout_right_region_key "$candidate_windows")
if [ "$target_side" = left ]; then
  target_key="$left_key"
  source_key="$right_key"
else
  target_key="$right_key"
  source_key="$left_key"
fi

target_windows=$(layout_windows_in_frame "$candidate_windows" "$target_key")
source_windows=$(layout_windows_in_frame "$candidate_windows" "$source_key")
target_count=$(layout_candidate_count "$target_windows")
source_count=$(layout_candidate_count "$source_windows")
target_anchor=$(layout_visible_id_in_frame "$candidate_windows" "$target_key")
[ -n "$target_anchor" ] || exit 0

if [ "$source_count" -gt 1 ]; then
  yabai -m window "$target_anchor" --stack "$window_id" 2>/dev/null || exit 0
elif [ "$target_count" -eq 1 ]; then
  # With one window on each side, moving the final source member is a side swap.
  yabai -m window "$window_id" --swap "$target_anchor" 2>/dev/null || exit 0
else
  # First extract a non-anchor replacement from the destination stack into the
  # source leaf. Stacking the requested window onto the destination then
  # collapses the temporary split and leaves the replacement on the old side.
  replacement_id=$(layout_replacement_id "$target_windows" "$target_anchor")
  [ -n "$replacement_id" ] || exit 0
  yabai -m window "$replacement_id" --warp "$window_id" 2>/dev/null || exit 0
  yabai -m window "$target_anchor" --stack "$window_id" 2>/dev/null || exit 0
fi

yabai -m window "$window_id" --focus 2>/dev/null || :
"$layout_script_dir/apply-layout.sh"
