#!/usr/bin/env sh

# Display-aware layout:
# - wide displays (aspect >= 2.0): BSP, 16 padding, 12 gap
#   - one managed window: centered at 70% width
#   - multiple managed windows: 45/55 vertical split, saved main on right, others stacked left
# - normal displays: stack, 10 padding, 8 gap

wide_threshold="2.0"
wide_solo_ratio="0.7"
wide_split_ratio="0.45"
wide_ratio_tolerance="0.01"
wide_top_padding="8"
wide_padding="16"
wide_gap="12"
normal_top_padding="8"
normal_padding="10"
normal_gap="8"
state_dir="$HOME/.local/state/yabai"
force_layout=0

case "${1:-}" in
  --force|force|reset) force_layout=1 ;;
esac

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
space_index=$(printf '%s' "$space_json" | jq -r '.index')
space_type=$(printf '%s' "$space_json" | jq -r '.type')
[ -n "$space_id" ] && [ "$space_id" != "null" ] || exit 0
[ -n "$space_index" ] && [ "$space_index" != "null" ] || exit 0

main_state_file="$state_dir/main-$space_id"
settings_state_file="$state_dir/settings-$space_id"
settings_dirty="$force_layout"
space_settings_changed=0

# Include the yabai daemon pid in the settings cache key so persisted state does
# not suppress required gap/padding re-application after yabai restarts.
yabai_pid=$(pgrep -x yabai 2>/dev/null | awk 'NR == 1 { print; exit }')
[ -n "$yabai_pid" ] || yabai_pid="unknown"
settings_cache_prefix="v2 pid=$yabai_pid"

set_space_layout() {
  desired="$1"
  if [ "$space_type" != "$desired" ]; then
    if yabai -m space --layout "$desired"; then
      space_type="$desired"
      settings_dirty=1
    fi
  fi
}

apply_space_settings() {
  mode="$1"
  gap="$2"
  top="$3"
  bottom="$4"
  left="$5"
  right="$6"

  desired="$settings_cache_prefix mode=$mode gap=$gap padding=$top:$bottom:$left:$right"
  current=""
  if [ -f "$settings_state_file" ]; then
    IFS= read -r current <"$settings_state_file" || current=""
  fi

  space_settings_changed=0
  if [ "$settings_dirty" -eq 1 ] || [ "$current" != "$desired" ]; then
    if yabai -m space --gap abs:"$gap" && yabai -m space --padding abs:"$top":"$bottom":"$left":"$right"; then
      printf '%s\n' "$desired" >"$settings_state_file" 2>/dev/null
      settings_dirty=0
      space_settings_changed=1
    fi
  fi
}

display_json=$(yabai -m query --displays --display 2>/dev/null) || exit 0
[ -n "$display_json" ] || exit 0

w=$(printf '%s' "$display_json" | jq -r '.frame.w')
h=$(printf '%s' "$display_json" | jq -r '.frame.h')
is_wide=$(awk "BEGIN { print (($w / $h) >= $wide_threshold) ? 1 : 0 }")

if [ "$is_wide" -eq 1 ]; then
  set_space_layout bsp

  windows_json=$(yabai -m query --windows --space 2>/dev/null) || exit 0

  candidate_windows=$(printf '%s' "$windows_json" | jq '[.[] | select(."is-floating" == false and ."is-minimized" == false and ."is-hidden" == false)]')
  managed_windows=$(printf '%s' "$candidate_windows" | jq '[.[] | select(."split-child" != "none" or ."stack-index" > 0)]')
  managed_count=$(printf '%s' "$managed_windows" | jq 'length')

  # When there is only one tile candidate, it may report split-child=none.
  if [ "$managed_count" -eq 0 ] && [ "$(printf '%s' "$candidate_windows" | jq 'length')" -eq 1 ]; then
    managed_windows="$candidate_windows"
    managed_count=1
  fi

  if [ "$managed_count" -le 1 ]; then
    if [ "$managed_count" -eq 1 ]; then
      only_id=$(printf '%s' "$managed_windows" | jq -r '.[0].id')
      printf '%s\n' "$only_id" >"$main_state_file" 2>/dev/null
    fi

    # Apply solo padding even when the query briefly returns 0 managed windows during space switches.
    side_padding=$(awk "BEGIN { printf \"%d\", ($w * (1 - $wide_solo_ratio) / 2) }")
    apply_space_settings "wide-solo" "$wide_gap" "$wide_top_padding" "$wide_padding" "$side_padding" "$side_padding"
  elif [ "$managed_count" -gt 1 ]; then
    apply_space_settings "wide-multi" "$wide_gap" "$wide_top_padding" "$wide_padding" "$wide_padding" "$wide_padding"
    did_mutate="$space_settings_changed"

    # Keep split type local to this space; split_ratio is global-only in yabai.
    yabai -m config --space "$space_index" split_type vertical
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
      if yabai -m window "$main_id" --warp east 2>/dev/null; then
        did_mutate=1
        sleep 0.05

        windows_json=$(yabai -m query --windows --space 2>/dev/null) || exit 0
        candidate_windows=$(printf '%s' "$windows_json" | jq '[.[] | select(."is-floating" == false and ."is-minimized" == false and ."is-hidden" == false)]')
        managed_windows=$(printf '%s' "$candidate_windows" | jq '[.[] | select(."split-child" != "none" or ."stack-index" > 0)]')
      fi
    fi

    anchor_id=$(printf '%s' "$managed_windows" | jq -r --argjson main "$main_id" '[.[] | select(.id != $main)] | sort_by(.frame.x) | first.id')
    if [ -n "$main_id" ] && [ -n "$anchor_id" ] && [ "$main_id" != "$anchor_id" ]; then
      # Stack every non-main, non-anchor, currently unstacked window onto the left anchor.
      for id in $(printf '%s' "$managed_windows" | jq -r --argjson main "$main_id" --argjson anchor "$anchor_id" '.[] | select(.id != $main and .id != $anchor and ."stack-index" == 0) | .id'); do
        if yabai -m window "$anchor_id" --stack "$id" 2>/dev/null; then
          did_mutate=1
        fi
      done

      # Ensure main is to the right of the stack. Re-query only when prior
      # settings/stack/warp changes may have invalidated the frame data.
      updated_windows="$managed_windows"
      if [ "$did_mutate" -eq 1 ]; then
        updated_windows=$(yabai -m query --windows --space 2>/dev/null) || exit 0
      fi

      main_x=$(printf '%s' "$updated_windows" | jq -r --argjson id "$main_id" '.[] | select(.id == $id) | .frame.x')
      anchor_x=$(printf '%s' "$updated_windows" | jq -r --argjson id "$anchor_id" '.[] | select(.id == $id) | .frame.x')

      did_swap=0
      if [ -n "$main_x" ] && [ -n "$anchor_x" ] && awk "BEGIN { exit !($main_x < $anchor_x) }"; then
        if yabai -m window "$main_id" --swap east 2>/dev/null; then
          did_swap=1
          did_mutate=1
        fi
      fi

      # Existing BSP nodes can keep their old ratio across yabai restarts.
      # Force the parent split to 45/55 only after this script actually changed
      # layout/topology, or when invoked explicitly as a reset. Plain space_changed
      # runs should preserve manual resize.sh ratios.
      if [ "$did_mutate" -eq 1 ] || [ "$force_layout" -eq 1 ]; then
        if [ "$did_swap" -eq 1 ]; then
          updated_windows=$(yabai -m query --windows --space 2>/dev/null) || exit 0
        fi

        main_w=$(printf '%s' "$updated_windows" | jq -r --argjson id "$main_id" '.[] | select(.id == $id) | .frame.w')
        anchor_w=$(printf '%s' "$updated_windows" | jq -r --argjson id "$anchor_id" '.[] | select(.id == $id) | .frame.w')

        need_ratio=1
        if [ -n "$main_w" ] && [ -n "$anchor_w" ] && awk "BEGIN { sum = $anchor_w + $main_w; if (sum <= 0) exit 1; d = ($anchor_w / sum) - $wide_split_ratio; if (d < 0) d = -d; exit !(d <= $wide_ratio_tolerance) }"; then
          need_ratio=0
        fi

        if [ "$need_ratio" -eq 1 ]; then
          yabai -m window "$main_id" --ratio abs:"$wide_split_ratio" 2>/dev/null
        fi
      fi

      # Preserve current focus during automatic layout; switch-main.sh handles explicit main changes.
    fi
  fi
else
  set_space_layout stack
  apply_space_settings "normal" "$normal_gap" "$normal_top_padding" "$normal_padding" "$normal_padding" "$normal_padding"
fi
