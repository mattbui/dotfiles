#!/usr/bin/env sh

# Move the focused window to a space, prepare destination insertion, and follow.
# Source repair intentionally remains lazy.
# Usage: move-to-space.sh <space-selector>

space_selector="${1:-}"
[ -n "$space_selector" ] || exit 1

# shellcheck source=/dev/null
. "$(dirname "$0")/layout-lib.sh"

layout_require_commands || exit 0

window_json=$(yabai -m query --windows --window 2>/dev/null) || exit 0
window_id=$(printf '%s' "$window_json" | jq -r '.id // empty')
source_space=$(printf '%s' "$window_json" | jq -r '.space // empty')
[ -n "$window_id" ] && [ -n "$source_space" ] || exit 0

if ! layout_load_space "$space_selector"; then
  case "$space_selector" in
    prev) layout_load_space last || exit 0 ;;
    next) layout_load_space first || exit 0 ;;
    *) exit 0 ;;
  esac
fi
destination_space="$layout_space_index"

layout_load_display "$layout_space_display" || exit 0
if [ "$layout_is_wide" -eq 1 ]; then
  layout_apply_config_if_needed window_insertion_point first || exit 0
  layout_apply_config_if_needed window_placement first_child || exit 0
else
  layout_apply_config_if_needed window_insertion_point focused || exit 0
  layout_apply_config_if_needed window_placement second_child || exit 0
fi

if [ "$source_space" != "$destination_space" ]; then
  yabai -m window "$window_id" --space "$destination_space" || exit 0
fi
yabai -m space --focus "$destination_space" || exit 0

# Apply explicitly so the wrapper remains independently usable. The destination
# space-change signal may invoke the same command concurrently; the layout lock
# coalesces that into one pending rerun.
"$layout_script_dir/apply-layout.sh"
