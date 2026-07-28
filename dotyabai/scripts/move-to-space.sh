#!/usr/bin/env sh

# Move the focused window to a space and follow. Source repair remains lazy.
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

if [ "$source_space" != "$destination_space" ]; then
  yabai -m window "$window_id" --space "$destination_space" || exit 0
fi
yabai -m space --focus "$destination_space" || exit 0

# The destination space-change signal may invoke the same command concurrently;
# the shared layout lock coalesces that into one pending rerun.
"$layout_script_dir/apply-layout.sh"
