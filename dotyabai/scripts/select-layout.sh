#!/usr/bin/env sh

# Directly select the current labeled space's flexible layout.
# Usage: select-layout.sh single-stack|two-stack

requested="${1:-}"
case "$requested" in
  single-stack|two-stack) ;;
  *) exit 1 ;;
esac

# shellcheck source=/dev/null
. "$(dirname "$0")/layout-lib.sh"

notify_layout() {
  command -v osascript >/dev/null 2>&1 || return 0
  case "$1" in
    single-stack) message="Single stack" ;;
    two-stack) message="Two stacks" ;;
    *) return 0 ;;
  esac
  osascript -e "display notification \"$message\" with title \"yabai\" subtitle \"Layout\"" >/dev/null 2>&1
}

layout_require_commands || exit 0
layout_load_space || exit 0
layout_load_display || exit 0
layout_load_preferences

[ -n "$layout_state_file" ] || exit 0

crossing_pending=false
if [ -n "$last_area_class" ] && [ "$last_area_class" != "$layout_area_class" ]; then
  crossing_pending=true
fi

[ "$crossing_pending" = true ] || [ "$selected_layout" != "$requested" ] || exit 0

mkdir -p "$layout_state_root" 2>/dev/null || exit 0
if [ "$crossing_pending" = true ]; then
  layout_state_update "$layout_state_file" \
    selected_layout "$requested" \
    last_area_class "$layout_area_class" 2>/dev/null || exit 0
else
  layout_state_update "$layout_state_file" selected_layout "$requested" 2>/dev/null || exit 0
fi
"$layout_script_dir/apply-layout.sh" || exit 0
notify_layout "$requested"
printf '%s\n' "$requested"
