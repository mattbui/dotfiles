#!/usr/bin/env sh

# Intuitive focused-window resize for yabai.
# Usage: resize.sh grow|shrink

step_ratio="0.025"
floating_step="80"
solo_padding_step="80"
solo_vertical_padding="12"

action="$1"
[ "$action" = "grow" ] || [ "$action" = "shrink" ] || exit 1

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v awk >/dev/null 2>&1 || exit 0

window_json=$(yabai -m query --windows --window 2>/dev/null) || exit 0
[ -n "$window_json" ] || exit 0

is_floating=$(printf '%s' "$window_json" | jq -r '."is-floating"')

if [ "$is_floating" = "true" ]; then
  wx=$(printf '%s' "$window_json" | jq -r '.frame.x')
  wy=$(printf '%s' "$window_json" | jq -r '.frame.y')
  ww=$(printf '%s' "$window_json" | jq -r '.frame.w')
  wh=$(printf '%s' "$window_json" | jq -r '.frame.h')

  if [ "$action" = "grow" ]; then
    delta="$floating_step"
  else
    delta="-$floating_step"
  fi

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

  yabai -m window --move abs:"$nx":"$ny"
  yabai -m window --resize abs:"$nw":"$nh"
  exit 0
fi

split_child=$(printf '%s' "$window_json" | jq -r '."split-child"')

# Solo tiled window: there may be no BSP split ratio to adjust. Detect solo by
# counting current-space tiled candidates, not only by split-child, because yabai
# can still report a split-child briefly after layout changes/restarts.
windows_json=$(yabai -m query --windows --space 2>/dev/null) || windows_json="[]"
solo_count=$(printf '%s' "$windows_json" | jq '[.[] | select(."is-floating" == false and ."is-minimized" == false and ."is-hidden" == false)] | length')

if [ "$solo_count" -le 1 ]; then
  display_json=$(yabai -m query --displays --display 2>/dev/null) || exit 0

  dw=$(printf '%s' "$display_json" | jq -r '.frame.w')
  ww=$(printf '%s' "$window_json" | jq -r '.frame.w')

  if [ "$action" = "grow" ]; then
    delta="-$solo_padding_step"
  else
    delta="$solo_padding_step"
  fi

  side=$(awk "BEGIN {
  side = (($dw - $ww) / 2) + $delta;
  min_side = $dw * 0.05;
  max_side = $dw * 0.35;
  if (side < min_side) side = min_side;
  if (side > max_side) side = max_side;
  printf \"%d\", side;
}")

  # Width-only solo resize: change left/right padding, keep vertical padding fixed.
  yabai -m space --padding abs:"$solo_vertical_padding":"$solo_vertical_padding":"$side":"$side"
  exit 0
fi

case "$split_child:$action" in
  first_child:grow)   delta="$step_ratio" ;;
  first_child:shrink) delta="-$step_ratio" ;;
  second_child:grow)  delta="-$step_ratio" ;;
  second_child:shrink) delta="$step_ratio" ;;
  *) exit 0 ;;
esac

yabai -m window --ratio rel:"$delta"
