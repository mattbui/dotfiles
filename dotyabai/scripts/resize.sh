#!/usr/bin/env sh

# Intuitive focused-window resize for yabai.
# Usage: resize.sh grow|shrink [multiplier]

step_ratio="0.025"
floating_step="80"
solo_padding_step="80"

action="$1"
multiplier="${2:-1}"
[ "$action" = "grow" ] || [ "$action" = "shrink" ] || exit 1
case "$multiplier" in
  ''|*[!0-9]*) exit 1 ;;
esac
[ "$multiplier" -ge 1 ] || exit 1

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0
command -v awk >/dev/null 2>&1 || exit 0

step_ratio=$(awk "BEGIN { printf \"%.3f\", $step_ratio * $multiplier }")
floating_step=$((floating_step * multiplier))
solo_padding_step=$((solo_padding_step * multiplier))

state_dir="$HOME/.local/state/yabai"
# shellcheck source=/dev/null
. "$(dirname "$0")/layout-state.sh"

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

  yabai -m window --resize abs:"$nw":"$nh"
  yabai -m window --move abs:"$nx":"$ny"
  exit 0
fi

space_json=$(yabai -m query --spaces --space 2>/dev/null) || space_json=""
space_index=$(printf '%s' "$space_json" | jq -r '.index // empty' 2>/dev/null)
space_label=$(printf '%s' "$space_json" | jq -r '.label // empty' 2>/dev/null)
layout_state_file=""
layout_mode=""
if [ -n "$space_label" ]; then
  layout_state_file=$(layout_state_file_for_space_label "$space_label")
  if [ ! -f "$layout_state_file" ]; then
    "$HOME/.config/yabai/scripts/apply-layout.sh" 2>/dev/null
  fi
  layout_mode=$(layout_state_get "$layout_state_file" mode "")
fi

split_child=$(printf '%s' "$window_json" | jq -r '."split-child"')

case "$split_child:$action" in
  first_child:grow)   delta="$step_ratio" ;;
  first_child:shrink) delta="-$step_ratio" ;;
  second_child:grow)  delta="-$step_ratio" ;;
  second_child:shrink) delta="$step_ratio" ;;
  none:*)             delta="" ;;
  *) exit 0 ;;
esac

if [ -n "$delta" ]; then
  # If yabai has a real BSP parent for this window, ratio resize is enough.
  # Solo windows can briefly report a stale split-child after layout changes;
  # in that case --ratio fails, so fall through to the solo-padding resize.
  if yabai -m window --ratio rel:"$delta" 2>/dev/null; then
    if [ "$layout_mode" = "wide-multi" ] && [ -n "$layout_state_file" ]; then
      main_id=$(layout_state_get "$layout_state_file" main_id "")
      windows_json=$(yabai -m query --windows --space 2>/dev/null) || windows_json="[]"
      if [ -n "$main_id" ]; then
        main_w=$(printf '%s' "$windows_json" | jq -r --argjson id "$main_id" '.[] | select(.id == $id) | .frame.w' 2>/dev/null)
        anchor_w=$(printf '%s' "$windows_json" | jq -r --argjson id "$main_id" '[.[] | select(."is-floating" == false and ."is-minimized" == false and ."is-hidden" == false and .id != $id)] | sort_by(.frame.x) | first.frame.w // empty' 2>/dev/null)
        if [ -n "$main_w" ] && [ -n "$anchor_w" ]; then
          new_ratio=$(awk "BEGIN { sum=$main_w+$anchor_w; if (sum <= 0) exit 1; printf \"%.3f\", $anchor_w / sum }" 2>/dev/null)
          if [ -n "$new_ratio" ]; then
            new_ratio=$(clamp_ratio "$new_ratio")
            layout_state_update "$layout_state_file" split_ratio "$new_ratio" 2>/dev/null
          fi
        fi
      fi
    fi
    exit 0
  fi
fi

# Solo tiled window: there may be no BSP split ratio to adjust. Prefer layout
# state for mode detection; fall back to a space-wide query when state is absent.
solo_count=2
if [ "$layout_mode" = "wide-solo" ]; then
  solo_count=1
else
  windows_json=$(yabai -m query --windows --space 2>/dev/null) || windows_json="[]"
  solo_count=$(printf '%s' "$windows_json" | jq '[.[] | select(."is-floating" == false and ."is-minimized" == false and ."is-hidden" == false)] | length')
fi

if [ "$solo_count" -le 1 ]; then
  display_json=$(yabai -m query --displays --display 2>/dev/null) || exit 0
  space_index=$(printf '%s' "$window_json" | jq -r '.space')
  if [ -z "$layout_state_file" ]; then
    space_json=$(yabai -m query --spaces --space "$space_index" 2>/dev/null) || space_json=""
    space_label=$(printf '%s' "$space_json" | jq -r '.label // empty' 2>/dev/null)
    [ -n "$space_label" ] && layout_state_file=$(layout_state_file_for_space_label "$space_label")
  fi

  dw=$(printf '%s' "$display_json" | jq -r '.frame.w')
  ww=$(printf '%s' "$window_json" | jq -r '.frame.w')
  sp_top=$(layout_state_get "$layout_state_file" padding_top "")
  sp_bottom=$(layout_state_get "$layout_state_file" padding_bottom "")
  [ -n "$sp_top" ] || sp_top=$(yabai -m config --space "$space_index" top_padding 2>/dev/null || printf '0')
  [ -n "$sp_bottom" ] || sp_bottom=$(yabai -m config --space "$space_index" bottom_padding 2>/dev/null || printf '0')

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

  # Width-only solo resize: change left/right padding, preserve current vertical padding.
  yabai -m space --padding abs:"$sp_top":"$sp_bottom":"$side":"$side"
  if [ -n "$layout_state_file" ] && [ "$layout_mode" = "wide-solo" ]; then
    solo_ratio=$(awk "BEGIN { printf \"%.3f\", 1 - (($side * 2) / $dw) }" 2>/dev/null)
    [ -n "$solo_ratio" ] && layout_state_update "$layout_state_file" solo_ratio "$solo_ratio" padding_top "$sp_top" padding_bottom "$sp_bottom" padding_left "$side" padding_right "$side" 2>/dev/null
  fi
  exit 0
fi

exit 0
