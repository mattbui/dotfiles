#!/usr/bin/env sh

# Resize the focused floating window or active flexible tiled arrangement.
# Usage: resize.sh grow|shrink [multiplier]

step_ratio="0.025"
floating_step="80"
action="${1:-}"
multiplier="${2:-1}"
[ "$action" = grow ] || [ "$action" = shrink ] || exit 1
case "$multiplier" in
  ''|*[!0-9]*) exit 1 ;;
esac
[ "$multiplier" -ge 1 ] || exit 1

# shellcheck source=/dev/null
. "$(dirname "$0")/layout-lib.sh"

layout_require_commands || exit 0
step_ratio=$(awk "BEGIN { printf \"%.3f\", $step_ratio * $multiplier }")
floating_step=$((floating_step * multiplier))

window_json=$(yabai -m query --windows --window 2>/dev/null) || exit 0
[ -n "$window_json" ] || exit 0
is_floating=$(printf '%s' "$window_json" | jq -r '."is-floating"')

if [ "$is_floating" = true ]; then
  wx=$(printf '%s' "$window_json" | jq -r '.frame.x')
  wy=$(printf '%s' "$window_json" | jq -r '.frame.y')
  ww=$(printf '%s' "$window_json" | jq -r '.frame.w')
  wh=$(printf '%s' "$window_json" | jq -r '.frame.h')
  if [ "$action" = grow ]; then delta="$floating_step"; else delta="-$floating_step"; fi
  read -r nx ny nw nh <<EOF
$(awk "BEGIN {
  nw=$ww+$delta; nh=$wh+$delta;
  if (nw < 300) nw=300;
  if (nh < 200) nh=200;
  nx=$wx-((nw-$ww)/2); ny=$wy-((nh-$wh)/2);
  printf \"%d %d %d %d\", nx, ny, nw, nh
}")
EOF
  yabai -m window --resize abs:"$nw":"$nh"
  yabai -m window --move abs:"$nx":"$ny"
  exit 0
fi

window_id=$(printf '%s' "$window_json" | jq -r '.id // empty')
window_space=$(printf '%s' "$window_json" | jq -r '.space // empty')
[ -n "$window_id" ] && [ -n "$window_space" ] || exit 0
layout_load_space "$window_space" || exit 0
layout_load_display || exit 0
[ -n "$layout_state_file" ] || exit 0

if [ ! -f "$layout_state_file" ]; then
  "$layout_script_dir/apply-layout.sh" >/dev/null 2>&1 || exit 0
fi
layout_load_preferences
candidate_windows=$(layout_query_candidates) || exit 0
candidate_count=$(layout_candidate_count "$candidate_windows")

layout_update_ratio() {
  key="$1"
  current="$2"
  minimum="$3"
  maximum="$4"
  direction="$5"
  effective=$(awk "BEGIN { v=$current; m=$maximum; if (v > m) v=m; printf \"%.3f\", v }")
  if [ "$direction" = grow ]; then
    updated=$(awk "BEGIN { v=$effective+$step_ratio; m=$maximum; if (v > m) v=m; printf \"%.3f\", v }")
  else
    updated=$(awk "BEGIN { v=$effective-$step_ratio; m=$minimum; if (v < m) v=m; printf \"%.3f\", v }")
  fi
  [ "$updated" != "$effective" ] || return 0
  layout_state_update "$layout_state_file" "$key" "$updated" 2>/dev/null || return 1
  "$layout_script_dir/apply-layout.sh" >/dev/null 2>&1
}

if [ "$selected_layout" = single-stack ] || [ "$candidate_count" -le 1 ]; then
  if [ "$layout_orientation" = portrait ]; then
    max_ratio=$(awk "BEGIN { printf \"%.3f\", ($layout_display_h - $layout_top_padding - $layout_base_padding) / $layout_display_h }")
    layout_update_ratio single_height_ratio "$single_height_ratio" 0.30 "$max_ratio" "$action"
  elif [ "$layout_is_ultrawide" -eq 1 ]; then
    max_ratio=$(awk "BEGIN { printf \"%.3f\", ($layout_display_w - 2 * $layout_base_padding) / $layout_display_w }")
    layout_update_ratio single_width_ratio "$single_width_ratio" 0.30 "$max_ratio" "$action"
  fi
  exit 0
fi

[ "$selected_layout" = two-stack ] || exit 0
layout_valid_two_stack "$candidate_windows" || exit 0
focused_region=$(layout_region_for_id "$candidate_windows" "$window_id")
[ -n "$focused_region" ] || exit 0

if [ "$layout_orientation" = portrait ]; then
  ratio_key="vertical_split_ratio"
  current_ratio="$vertical_split_ratio"
else
  ratio_key="horizontal_split_ratio"
  current_ratio="$horizontal_split_ratio"
fi

case "$focused_region:$action" in
  first:grow|second:shrink) ratio_direction="grow" ;;
  first:shrink|second:grow) ratio_direction="shrink" ;;
  *) exit 0 ;;
esac
layout_update_ratio "$ratio_key" "$current_ratio" 0.10 0.90 "$ratio_direction"
