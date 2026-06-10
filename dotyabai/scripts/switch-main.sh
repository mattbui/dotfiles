#!/usr/bin/env sh

# Switch the main window for the current space, then re-apply layout.
# - If a non-main window is focused: make it main.
# - If the saved main is focused: make the currently visible left-stack window main.

state_dir="$HOME/.local/state/yabai"
mkdir -p "$state_dir" 2>/dev/null
# shellcheck source=/dev/null
. "$(dirname "$0")/layout-state.sh"

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

space_json=$(yabai -m query --spaces --space 2>/dev/null) || exit 0
space_index=$(printf '%s' "$space_json" | jq -r '.index')
[ -n "$space_index" ] && [ "$space_index" != "null" ] || exit 0
layout_state_file=$(layout_state_file_for_space "$space_index")

window_json=$(yabai -m query --windows --window 2>/dev/null) || exit 0
window_id=$(printf '%s' "$window_json" | jq -r '.id')
is_floating=$(printf '%s' "$window_json" | jq -r '."is-floating"')
is_minimized=$(printf '%s' "$window_json" | jq -r '."is-minimized"')

[ -n "$window_id" ] && [ "$window_id" != "null" ] || exit 0
[ "$is_floating" = "false" ] || exit 0
[ "$is_minimized" = "false" ] || exit 0

saved_main_id=$(layout_state_get "$layout_state_file" main_id "")

new_main_id="$window_id"
new_main_json="$window_json"

if [ -n "$saved_main_id" ] && [ "$window_id" = "$saved_main_id" ]; then
  # Main is focused. Pick the currently visible/focused window in the left stack
  # by asking yabai to focus west, then reading the newly focused window.
  if yabai -m window --focus west 2>/dev/null; then
    new_main_json=$(yabai -m query --windows --window 2>/dev/null) || exit 0
    new_main_id=$(printf '%s' "$new_main_json" | jq -r '.id')
  else
    exit 0
  fi
fi

[ -n "$new_main_id" ] && [ "$new_main_id" != "null" ] || exit 0
layout_state_update "$layout_state_file" main_id "$new_main_id" 2>/dev/null || exit 0

# If the new main is inside a stack, pull that individual window out first.
# Warp un-stacks the target window; apply-layout.sh will then place it as main and
# stack every other managed window on the left.
stack_index=$(printf '%s' "$new_main_json" | jq -r '."stack-index"')
if [ "$stack_index" != "0" ]; then
  yabai -m window "$new_main_id" --warp east 2>/dev/null
fi

$HOME/.config/yabai/scripts/apply-layout.sh
