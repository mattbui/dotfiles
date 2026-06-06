#!/usr/bin/env sh

# Toggle float modes.
# Usage:
#   toggle-float.sh center      -> centered floating window, 80% display height, 120% display-height width
#   toggle-float.sh fullscreen  -> centered floating window, 90% display width, 90% display height

mode="${1:-center}"
height_ratio="0.80"
width_height_ratio="1.20"
fullscreen_ratio="0.90"

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v awk >/dev/null 2>&1 || exit 0

case "$mode" in
  center|fullscreen) ;;
  *) exit 1 ;;
esac

yabai -m window --toggle float

window_json=$(yabai -m query --windows --window 2>/dev/null) || exit 0
[ -n "$window_json" ] || exit 0

is_floating=$(printf '%s' "$window_json" | jq -r '."is-floating"')
if [ "$is_floating" != "true" ]; then
  $HOME/.config/yabai/scripts/layout.sh
  exit 0
fi

display_id=$(printf '%s' "$window_json" | jq -r '.display')
display_json=$(yabai -m query --displays --display "$display_id" 2>/dev/null) || exit 0
[ -n "$display_json" ] || exit 0

# Use the display's visible frame. This excludes menu bar / dock areas and
# matches the coordinate system yabai uses for tiled windows better than frame.
dx=$(printf '%s' "$display_json" | jq -r '."visible-frame".x // .frame.x')
dy=$(printf '%s' "$display_json" | jq -r '."visible-frame".y // .frame.y')
dw=$(printf '%s' "$display_json" | jq -r '."visible-frame".w // .frame.w')
dh=$(printf '%s' "$display_json" | jq -r '."visible-frame".h // .frame.h')

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

# Resize first, then move. Some apps adjust origin asynchronously during resize,
# so move twice to preserve the requested padding.
yabai -m window --resize abs:"$w":"$h"
yabai -m window --move abs:"$x":"$y"
sleep 0.05
yabai -m window --move abs:"$x":"$y"
