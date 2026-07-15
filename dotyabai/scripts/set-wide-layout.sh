#!/usr/bin/env sh

# Set or toggle the per-space wide-layout preference.
# Usage: set-wide-layout.sh two-stack|center-stack|toggle

requested="${1:-toggle}"
case "$requested" in
  two-stack|center-stack|toggle) ;;
  *) exit 1 ;;
esac

# shellcheck source=/dev/null
. "$(dirname "$0")/layout-lib.sh"

notify_layout() {
  command -v osascript >/dev/null 2>&1 || return 0

  case "$1" in
    two-stack) message="Two stacks" ;;
    center-stack) message="Centered stack" ;;
    *) return 0 ;;
  esac

  osascript -e "display notification \"$message\" with title \"yabai\" subtitle \"Wide layout\"" >/dev/null 2>&1
}

layout_require_commands || exit 0
layout_load_space || exit 0
layout_load_display || exit 0
[ "$layout_is_wide" -eq 1 ] || exit 0

current=$(layout_read_preference)
if [ "$requested" = "toggle" ]; then
  if [ "$current" = "two-stack" ]; then
    requested="center-stack"
  else
    requested="two-stack"
  fi
fi

mkdir -p "$layout_state_root" 2>/dev/null || exit 0
layout_state_update "$layout_state_file" wide_layout "$requested" 2>/dev/null || exit 0
"$layout_script_dir/apply-layout.sh" || exit 0
notify_layout "$requested"
printf '%s\n' "$requested"
