#!/usr/bin/env sh

# Toggle float modes.
# Usage:
#   toggle-float.sh center      -> centered floating window, 80% tiling-area height, 120% tiling-area-height width
#   toggle-float.sh fullscreen  -> centered floating window, 100% tiling-area width, 100% tiling-area height

mode="${1:-center}"
height_ratio="0.80"
width_height_ratio="1.20"
fullscreen_ratio="1.00"

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v awk >/dev/null 2>&1 || exit 0

state_dir="$HOME/.local/state/yabai"
# shellcheck source=/dev/null
. "$(dirname "$0")/layout-state.sh"

case "$mode" in
  center|fullscreen) ;;
  *) exit 1 ;;
esac

yabai -m window --toggle float

window_json=$(yabai -m query --windows --window 2>/dev/null) || exit 0
[ -n "$window_json" ] || exit 0

is_floating=$(printf '%s' "$window_json" | jq -r '."is-floating"')
if [ "$is_floating" != "true" ]; then
  $HOME/.config/yabai/scripts/apply-layout.sh
  exit 0
fi

display_id=$(printf '%s' "$window_json" | jq -r '.display')
display_json=$(yabai -m query --displays --display "$display_id" 2>/dev/null) || exit 0
[ -n "$display_json" ] || exit 0

# Start from the display's visible frame. This excludes menu bar / dock areas
# when available and is closest to yabai's constrained display bounds.
dx=$(printf '%s' "$display_json" | jq -r '."visible-frame".x // .frame.x')
dy=$(printf '%s' "$display_json" | jq -r '."visible-frame".y // .frame.y')
dw=$(printf '%s' "$display_json" | jq -r '."visible-frame".w // .frame.w')
dh=$(printf '%s' "$display_json" | jq -r '."visible-frame".h // .frame.h')

menu_bar_height="0"
top_reserved_height="0"
if [ "$mode" = "fullscreen" ]; then
  command -v osascript >/dev/null 2>&1 || exit 0

  # yabai does not expose its constrained display bounds in query --displays.
  # Account for the macOS menu bar / top reserved area using NSScreen.visibleFrame.
  menu_bar_height=$(osascript -l JavaScript <<'EOF' 2>/dev/null || printf '0'
ObjC.import('AppKit')
const s = $.NSScreen.mainScreen
const f = s.frame
const v = s.visibleFrame
Math.max(0, f.size.height - v.size.height - v.origin.y)
EOF
)
  [ -n "$menu_bar_height" ] || menu_bar_height="0"
  top_reserved_height="$menu_bar_height"
fi

# Match yabai's tiling area by applying the current space's padding on top of
# the constrained display bounds. See .src/yabai/src/view.c:view_update().
space_index=$(printf '%s' "$window_json" | jq -r '.space')
layout_state_file=""
[ -n "$space_index" ] && layout_state_file=$(layout_state_file_for_space "$space_index")

sp_top=$(layout_state_get "$layout_state_file" padding_top "")
sp_bottom=$(layout_state_get "$layout_state_file" padding_bottom "")
sp_left=$(layout_state_get "$layout_state_file" padding_left "")
sp_right=$(layout_state_get "$layout_state_file" padding_right "")
[ -n "$sp_top" ] || sp_top=$(yabai -m config --space "$space_index" top_padding 2>/dev/null || printf '0')
[ -n "$sp_bottom" ] || sp_bottom=$(yabai -m config --space "$space_index" bottom_padding 2>/dev/null || printf '0')
[ -n "$sp_left" ] || sp_left=$(yabai -m config --space "$space_index" left_padding 2>/dev/null || printf '0')
[ -n "$sp_right" ] || sp_right=$(yabai -m config --space "$space_index" right_padding 2>/dev/null || printf '0')

# In wide-solo mode, left/right padding is intentionally large to center the
# single tiled window. For floating fullscreen, use the regular edge padding
# instead so the window can occupy the full usable display width.
layout_mode=$(layout_state_get "$layout_state_file" mode "")
if [ "$mode" = "fullscreen" ] && [ "$layout_mode" = "wide-solo" ]; then
  sp_left="$sp_bottom"
  sp_right="$sp_bottom"
fi

read -r dx dy dw dh <<EOF
$(awk "BEGIN {
  dx = $dx + $sp_left;
  dy = $dy + $top_reserved_height + $sp_top;
  dw = $dw - ($sp_left + $sp_right);
  dh = $dh - ($top_reserved_height + $sp_top + $sp_bottom);
  if (dw < 1) dw = 1;
  if (dh < 1) dh = 1;
  printf \"%d %d %d %d\", dx, dy, dw, dh;
}")
EOF

if [ "$mode" = "fullscreen" ]; then
  read -r x y w h <<EOF
$(awk "BEGIN {
  w = $dw * $fullscreen_ratio;
  h = $dh * $fullscreen_ratio;
  x = $dx + (($dw - w) / 2);
  y = $dy + (($dh - h) / 2);
  printf \"%d %d %d %d\", x, y, w, h;
}")
EOF
else
  read -r x y w h <<EOF
$(awk "BEGIN {
  h = $dh * $height_ratio;
  w = $dh * $width_height_ratio;
  x = $dx + (($dw - w) / 2);
  y = $dy + (($dh - h) / 2);
  printf \"%d %d %d %d\", x, y, w, h;
}")
EOF
fi

# For fullscreen, move first. If the window starts centered with large
# wide-solo padding, resizing to display width before moving can be clamped by
# macOS/yabai at the current x position, leaving a right-side gap.
if [ "$mode" = "fullscreen" ]; then
  yabai -m window --move abs:"$x":"$y"
  sleep 0.01
  yabai -m window --resize abs:"$w":"$h"
  yabai -m window --move abs:"$x":"$y"
else
  # Resize before move so JankyBorders receives the expensive size update before
  # the cheap move update. This avoids briefly showing an old-size border at the
  # final floated position.
  yabai -m window --resize abs:"$w":"$h"
  yabai -m window --move abs:"$x":"$y"
fi

if [ "$mode" = "center" ]; then
  $HOME/.config/yabai/scripts/apply-layout.sh
fi
