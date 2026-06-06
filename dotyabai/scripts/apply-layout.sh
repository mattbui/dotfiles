#!/usr/bin/env sh

# Display-aware layout:
# - wide displays (aspect >= 2.0): BSP, 12 padding, 10 gap
#   - one managed window: centered at 65% width
#   - multiple managed windows: 45/55 vertical split, saved main on right, others stacked left
# - normal displays: stack, 10 padding, 8 gap

wide_threshold="2.0"
solo_ratio="0.65"
wide_split_ratio="0.45"
wide_top_padding="6"
wide_padding="12"
wide_gap="10"
normal_top_padding="6"
normal_padding="10"
normal_gap="8"
state_dir="$HOME/.local/state/yabai"

mkdir -p "$state_dir" 2>/dev/null

lock_dir="$state_dir/layout.lock"
if ! mkdir "$lock_dir" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "$lock_dir" 2>/dev/null' EXIT INT TERM

require() {
  command -v "$1" >/dev/null 2>&1 || exit 0
}

require yabai
require jq
require awk

space_json=$(yabai -m query --spaces --space 2>/dev/null) || exit 0
space_id=$(printf '%s' "$space_json" | jq -r '.id')
space_type=$(printf '%s' "$space_json" | jq -r '.type')
main_state_file="$state_dir/main-$space_id"

set_space_layout() {
  desired="$1"
  if [ "$space_type" != "$desired" ]; then
    yabai -m space --layout "$desired"
    space_type="$desired"
  fi
}

display_json=$(yabai -m query --displays --display 2>/dev/null) || exit 0
[ -n "$display_json" ] || exit 0

w=$(printf '%s' "$display_json" | jq -r '.frame.w')
h=$(printf '%s' "$display_json" | jq -r '.frame.h')
is_wide=$(awk "BEGIN { print (($w / $h) >= $wide_threshold) ? 1 : 0 }")

windows_json=$(yabai -m query --windows --space 2>/dev/null) || exit 0

candidate_windows=$(printf '%s' "$windows_json" | jq '[.[] | select(."is-floating" == false and ."is-minimized" == false and ."is-hidden" == false)]')
managed_windows=$(printf '%s' "$candidate_windows" | jq '[.[] | select(."split-child" != "none" or ."stack-index" > 0)]')
managed_count=$(printf '%s' "$managed_windows" | jq 'length')

# When there is only one tile candidate, it may report split-child=none.
if [ "$managed_count" -eq 0 ] && [ "$(printf '%s' "$candidate_windows" | jq 'length')" -eq 1 ]; then
  managed_windows="$candidate_windows"
  managed_count=1
fi

if [ "$is_wide" -eq 1 ]; then
  set_space_layout bsp
  yabai -m space --gap abs:"$wide_gap"

  if [ "$managed_count" -le 1 ]; then
    if [ "$managed_count" -eq 1 ]; then
      only_id=$(printf '%s' "$managed_windows" | jq -r '.[0].id')
      printf '%s\n' "$only_id" >"$main_state_file" 2>/dev/null
    fi

    # Apply solo padding even when the query briefly returns 0 managed windows during space switches.
    side_padding=$(awk "BEGIN { printf \"%d\", ($w * (1 - $solo_ratio) / 2) }")
    yabai -m space --padding abs:"$wide_top_padding":"$wide_padding":"$side_padding":"$side_padding"
  elif [ "$managed_count" -gt 1 ]; then
    yabai -m space --padding abs:"$wide_top_padding":"$wide_padding":"$wide_padding":"$wide_padding"
    yabai -m config split_type vertical
    yabai -m config split_ratio "$wide_split_ratio"

    saved_main_id=""
    [ -f "$main_state_file" ] && saved_main_id=$(cat "$main_state_file" 2>/dev/null)

    if [ -n "$saved_main_id" ] && printf '%s' "$managed_windows" | jq -e --argjson id "$saved_main_id" 'any(.[]; .id == $id)' >/dev/null 2>&1; then
      main_id="$saved_main_id"
    else
      main_id=$(printf '%s' "$managed_windows" | jq -r 'sort_by(.frame.x) | last.id')
      printf '%s\n' "$main_id" >"$main_state_file" 2>/dev/null
    fi

    # If the saved/promoted main is currently inside a stack, unstack it first.
    # Otherwise stacking the old main into the left side can leave every window in one fullscreen stack.
    main_stack_index=$(printf '%s' "$managed_windows" | jq -r --argjson main "$main_id" '.[] | select(.id == $main) | ."stack-index"')
    if [ -n "$main_stack_index" ] && [ "$main_stack_index" != "0" ]; then
      yabai -m window "$main_id" --warp east 2>/dev/null
      sleep 0.05

      windows_json=$(yabai -m query --windows --space 2>/dev/null) || exit 0
      candidate_windows=$(printf '%s' "$windows_json" | jq '[.[] | select(."is-floating" == false and ."is-minimized" == false and ."is-hidden" == false)]')
      managed_windows=$(printf '%s' "$candidate_windows" | jq '[.[] | select(."split-child" != "none" or ."stack-index" > 0)]')
    fi

    anchor_id=$(printf '%s' "$managed_windows" | jq -r --argjson main "$main_id" '[.[] | select(.id != $main)] | sort_by(.frame.x) | first.id')
    if [ -n "$main_id" ] && [ -n "$anchor_id" ] && [ "$main_id" != "$anchor_id" ]; then
      # Stack every non-main, non-anchor, currently unstacked window onto the left anchor.
      for id in $(printf '%s' "$managed_windows" | jq -r --argjson main "$main_id" --argjson anchor "$anchor_id" '.[] | select(.id != $main and .id != $anchor and ."stack-index" == 0) | .id'); do
        yabai -m window "$anchor_id" --stack "$id" 2>/dev/null
      done

      # Ensure main is to the right of the stack.
      updated_windows=$(yabai -m query --windows --space 2>/dev/null) || exit 0
      main_x=$(printf '%s' "$updated_windows" | jq -r --argjson id "$main_id" '.[] | select(.id == $id) | .frame.x')
      anchor_x=$(printf '%s' "$updated_windows" | jq -r --argjson id "$anchor_id" '.[] | select(.id == $id) | .frame.x')

      if [ -n "$main_x" ] && [ -n "$anchor_x" ] && awk "BEGIN { exit !($main_x < $anchor_x) }"; then
        yabai -m window "$main_id" --swap east 2>/dev/null
      fi

      # Existing BSP nodes can keep their old ratio across yabai restarts.
      # Force the parent split to 45/55 after the left stack/right main structure is in place.
      yabai -m window "$main_id" --ratio abs:"$wide_split_ratio" 2>/dev/null

      # Preserve current focus during automatic layout; switch-main.sh handles explicit main changes.
    fi
  fi
else
  set_space_layout stack
  yabai -m space --gap abs:"$normal_gap"
  yabai -m space --padding abs:"$normal_top_padding":"$normal_padding":"$normal_padding":"$normal_padding"
fi
