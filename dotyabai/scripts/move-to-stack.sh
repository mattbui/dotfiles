#!/usr/bin/env sh

# Move the focused eligible tiled window to a two-stack region.
# Usage: move-to-stack.sh left|right|top|bottom

target_direction="${1:-}"
case "$target_direction" in
  left|right|top|bottom) ;;
  *) exit 1 ;;
esac

# shellcheck source=/dev/null
. "$(dirname "$0")/layout-lib.sh"

layout_require_commands || exit 0
layout_load_space || exit 0
layout_load_display || exit 0
layout_load_preferences

case "$layout_orientation:$target_direction" in
  landscape:left|portrait:top) target_region="first" ;;
  landscape:right|portrait:bottom) target_region="second" ;;
  *) exit 0 ;;
esac
[ "$selected_layout" = two-stack ] || exit 0

window_json=$(yabai -m query --windows --window 2>/dev/null) || exit 0
window_id=$(printf '%s' "$window_json" | jq -r '.id // empty')
is_floating=$(printf '%s' "$window_json" | jq -r '."is-floating"')
is_minimized=$(printf '%s' "$window_json" | jq -r '."is-minimized"')
[ -n "$window_id" ] && [ "$is_floating" = false ] && [ "$is_minimized" = false ] || exit 0

# Repair a collapsed, rotated, or manually altered tree before interpreting it.
"$layout_script_dir/apply-layout.sh" || exit 0
candidate_windows=$(layout_query_candidates) || exit 0
layout_valid_two_stack "$candidate_windows" || exit 0

current_region=$(layout_region_for_id "$candidate_windows" "$window_id")
[ -n "$current_region" ] || exit 0
[ "$current_region" != "$target_region" ] || exit 0

first_key=$(layout_first_region_key "$candidate_windows")
second_key=$(layout_second_region_key "$candidate_windows")
if [ "$target_region" = first ]; then
  target_key="$first_key"
  source_key="$second_key"
else
  target_key="$second_key"
  source_key="$first_key"
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
  yabai -m window "$window_id" --swap "$target_anchor" 2>/dev/null || exit 0
else
  replacement_id=$(layout_replacement_id "$target_windows" "$target_anchor")
  [ -n "$replacement_id" ] || exit 0
  yabai -m window "$replacement_id" --warp "$window_id" 2>/dev/null || exit 0
  yabai -m window "$target_anchor" --stack "$window_id" 2>/dev/null || exit 0
fi

yabai -m window "$window_id" --focus 2>/dev/null || :
"$layout_script_dir/apply-layout.sh"
