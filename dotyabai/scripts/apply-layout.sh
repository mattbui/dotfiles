#!/usr/bin/env sh

# Display-aware layout:
# - wide displays (aspect >= 2.0): BSP, 12 padding (6 top), 10 gap
#   - one managed window: centered at 70% width
#   - multiple managed windows: 45/55 vertical split, saved main on right, others stacked left
# - normal displays: stack, 8 padding (6 top), 8 gap

wide_threshold="2.0"
wide_solo_ratio="0.7"
wide_split_ratio="0.45"
wide_ratio_tolerance="0.01"
wide_top_padding="6"
wide_padding="12"
wide_gap="10"
normal_top_padding="6"
normal_padding="8"
normal_gap="8"
state_dir="$HOME/.local/state/yabai"
reset_layout=0

case "${1:-}" in
  reset|--reset|force|--force) reset_layout=1 ;;
esac

mkdir -p "$state_dir" 2>/dev/null

lock_dir="$state_dir/layout.lock"
pending_file="$state_dir/layout.pending"
if ! mkdir "$lock_dir" 2>/dev/null; then
  : >"$pending_file" 2>/dev/null
  exit 0
fi
cleanup() {
  status=$?
  trap - EXIT INT TERM
  rmdir "$lock_dir" 2>/dev/null
  if [ -f "$pending_file" ]; then
    rm -f "$pending_file" 2>/dev/null
    "$0" >/dev/null 2>&1 &
  fi
  exit "$status"
}
trap cleanup EXIT INT TERM

require() {
  command -v "$1" >/dev/null 2>&1 || exit 0
}

require yabai
require jq
require awk

# shellcheck source=/dev/null
. "$(dirname "$0")/layout-state.sh"

space_json=$(yabai -m query --spaces --space 2>/dev/null) || exit 0
space_id=$(printf '%s' "$space_json" | jq -r '.id')
space_index=$(printf '%s' "$space_json" | jq -r '.index')
space_type=$(printf '%s' "$space_json" | jq -r '.type')
space_display=$(printf '%s' "$space_json" | jq -r '.display')
[ -n "$space_id" ] && [ "$space_id" != "null" ] || exit 0
[ -n "$space_index" ] && [ "$space_index" != "null" ] || exit 0
[ -n "$space_display" ] && [ "$space_display" != "null" ] || exit 0

layout_state_file=$(layout_state_file_for_space "$space_index")
old_main_state_file="$state_dir/main-$space_id"
settings_state_file="$state_dir/settings-$space_id"
settings_dirty="$reset_layout"
space_settings_changed=0

# Include the yabai daemon pid in the settings cache key so persisted state does
# not suppress required gap/padding re-application after yabai restarts.
yabai_pid=$(pgrep -x yabai 2>/dev/null | awk 'NR == 1 { print; exit }')
[ -n "$yabai_pid" ] || yabai_pid="unknown"
settings_cache_prefix="v2 pid=$yabai_pid"

set_space_layout() {
  desired="$1"

  if [ "$space_type" != "$desired" ]; then
    if yabai -m space "$space_index" --layout "$desired"; then
      space_type="$desired"
      settings_dirty=1
    fi
  fi
}

apply_space_settings() {
  mode="$1"
  placement="$2"
  insertion_point="$3"
  gap="$4"
  top="$5"
  bottom="$6"
  left="$7"
  right="$8"

  desired="$settings_cache_prefix mode=$mode placement=$placement insertion=$insertion_point gap=$gap padding=$top:$bottom:$left:$right"
  current=""
  if [ -f "$settings_state_file" ]; then
    IFS= read -r current <"$settings_state_file" || current=""
  fi

  space_settings_changed=0
  if [ "$settings_dirty" -eq 1 ] || [ "$current" != "$desired" ]; then
    if yabai -m config --space "$space_index" window_placement "$placement" && \
       yabai -m config --space "$space_index" window_insertion_point "$insertion_point" && \
       yabai -m space "$space_index" --gap abs:"$gap" && \
       yabai -m space "$space_index" --padding abs:"$top":"$bottom":"$left":"$right"; then
      printf '%s\n' "$desired" >"$settings_state_file" 2>/dev/null
      settings_dirty=0
      space_settings_changed=1
    fi
  fi
}

display_json=$(yabai -m query --displays --display "$space_display" 2>/dev/null) || exit 0
[ -n "$display_json" ] || exit 0

w=$(printf '%s' "$display_json" | jq -r '.frame.w')
h=$(printf '%s' "$display_json" | jq -r '.frame.h')
is_wide=$(awk "BEGIN { print (($w / $h) >= $wide_threshold) ? 1 : 0 }")

if [ "$is_wide" -eq 1 ]; then
  set_space_layout bsp

  windows_json=$(yabai -m query --windows --space "$space_index" 2>/dev/null) || exit 0

  candidate_windows=$(printf '%s' "$windows_json" | jq '[.[] | select(."is-floating" == false and ."is-minimized" == false and ."is-hidden" == false)]')
  candidate_count=$(printf '%s' "$candidate_windows" | jq 'length')

  if [ "$candidate_count" -le 1 ]; then
    if [ "$candidate_count" -eq 1 ]; then
      only_id=$(printf '%s' "$candidate_windows" | jq -r '.[0].id')
      layout_state_update "$layout_state_file" main_id "$only_id" 2>/dev/null
    fi

    # Apply solo padding even when the query briefly returns 0 managed windows during space switches.
    saved_solo_ratio=$(layout_state_get "$layout_state_file" solo_ratio "$wide_solo_ratio")
    if [ "$reset_layout" -eq 1 ] || ! valid_ratio "$saved_solo_ratio"; then
      saved_solo_ratio="$wide_solo_ratio"
    fi
    side_padding=$(awk "BEGIN { printf \"%d\", ($w * (1 - $saved_solo_ratio) / 2) }")
    apply_space_settings "wide-solo" first_child first "$wide_gap" "$wide_top_padding" "$wide_padding" "$side_padding" "$side_padding"
    saved_split_ratio=$(layout_state_get "$layout_state_file" split_ratio "$wide_split_ratio")
    valid_ratio "$saved_split_ratio" || saved_split_ratio="$wide_split_ratio"
    layout_state_update "$layout_state_file" mode wide-solo solo_ratio "$saved_solo_ratio" split_ratio "$saved_split_ratio" gap "$wide_gap" padding_top "$wide_top_padding" padding_bottom "$wide_padding" padding_left "$side_padding" padding_right "$side_padding" window_placement first_child window_insertion_point first 2>/dev/null
  elif [ "$candidate_count" -gt 1 ]; then
    apply_space_settings "wide-multi" first_child first "$wide_gap" "$wide_top_padding" "$wide_padding" "$wide_padding" "$wide_padding"
    did_mutate="$space_settings_changed"

    target_split_ratio=$(layout_state_get "$layout_state_file" split_ratio "$wide_split_ratio")
    if [ "$reset_layout" -eq 1 ] || ! valid_ratio "$target_split_ratio"; then
      target_split_ratio="$wide_split_ratio"
    fi
    saved_solo_ratio=$(layout_state_get "$layout_state_file" solo_ratio "$wide_solo_ratio")
    valid_ratio "$saved_solo_ratio" || saved_solo_ratio="$wide_solo_ratio"

    # Keep split type local to this space; split_ratio is global-only in yabai.
    yabai -m config --space "$space_index" split_type vertical
    yabai -m config split_ratio "$target_split_ratio"

    saved_main_id=$(layout_state_get "$layout_state_file" main_id "")
    if [ -z "$saved_main_id" ] && [ -f "$old_main_state_file" ]; then
      saved_main_id=$(cat "$old_main_state_file" 2>/dev/null)
    fi

    if [ -n "$saved_main_id" ] && printf '%s' "$candidate_windows" | jq -e --argjson id "$saved_main_id" 'any(.[]; .id == $id)' >/dev/null 2>&1; then
      main_id="$saved_main_id"
    else
      main_id=$(printf '%s' "$candidate_windows" | jq -r 'sort_by(.frame.x) | last.id')
      layout_state_update "$layout_state_file" main_id "$main_id" 2>/dev/null
    fi

    # If the saved/promoted main is currently inside a stack, unstack it first.
    # Otherwise stacking the old main into the left side can leave every window in one fullscreen stack.
    main_stack_index=$(printf '%s' "$candidate_windows" | jq -r --argjson main "$main_id" '.[] | select(.id == $main) | ."stack-index"')
    if [ -n "$main_stack_index" ] && [ "$main_stack_index" != "0" ]; then
      if yabai -m window "$main_id" --warp east 2>/dev/null; then
        did_mutate=1
        sleep 0.05

        windows_json=$(yabai -m query --windows --space "$space_index" 2>/dev/null) || exit 0
        candidate_windows=$(printf '%s' "$windows_json" | jq '[.[] | select(."is-floating" == false and ."is-minimized" == false and ."is-hidden" == false)]')
      fi
    fi

    # Prefer an existing stack member as the left anchor. A newly moved window
    # can briefly be the leftmost unstacked pane; choosing it as anchor would
    # leave the existing stack separate because stacked windows are skipped below.
    anchor_id=$(printf '%s' "$candidate_windows" | jq -r --argjson main "$main_id" '([.[] | select(.id != $main and ."stack-index" > 0)] | sort_by(.frame.x) | first.id) // ([.[] | select(.id != $main)] | sort_by(.frame.x) | first.id) // empty')
    if [ -n "$main_id" ] && [ -n "$anchor_id" ] && [ "$main_id" != "$anchor_id" ]; then
      # Stack every non-main, non-anchor, currently unstacked window onto the left anchor.
      for id in $(printf '%s' "$candidate_windows" | jq -r --argjson main "$main_id" --argjson anchor "$anchor_id" '.[] | select(.id != $main and .id != $anchor and ."stack-index" == 0) | .id'); do
        if yabai -m window "$anchor_id" --stack "$id" 2>/dev/null; then
          did_mutate=1
        fi
      done

      # Ensure main is to the right of the stack. Re-query only when prior
      # settings/stack/warp changes may have invalidated the frame data.
      updated_windows="$candidate_windows"
      if [ "$did_mutate" -eq 1 ]; then
        updated_windows=$(yabai -m query --windows --space "$space_index" 2>/dev/null) || exit 0
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

      # Treat the persisted split_ratio as the source of truth. On every
      # apply-layout run, infer the current left/main split from frames and
      # only call --ratio when it differs from the saved target beyond tolerance.
      if [ "$did_swap" -eq 1 ]; then
        updated_windows=$(yabai -m query --windows --space "$space_index" 2>/dev/null) || exit 0
      fi

      main_w=$(printf '%s' "$updated_windows" | jq -r --argjson id "$main_id" '.[] | select(.id == $id) | .frame.w')
      anchor_w=$(printf '%s' "$updated_windows" | jq -r --argjson id "$anchor_id" '.[] | select(.id == $id) | .frame.w')

      need_ratio=1
      if [ -n "$main_w" ] && [ -n "$anchor_w" ] && awk "BEGIN { sum = $anchor_w + $main_w; if (sum <= 0) exit 1; d = ($anchor_w / sum) - $target_split_ratio; if (d < 0) d = -d; exit !(d <= $wide_ratio_tolerance) }"; then
        need_ratio=0
      fi

      if [ "$need_ratio" -eq 1 ]; then
        yabai -m window "$main_id" --ratio abs:"$target_split_ratio" 2>/dev/null
      fi

      layout_state_update "$layout_state_file" mode wide-multi main_id "$main_id" split_ratio "$target_split_ratio" solo_ratio "$saved_solo_ratio" gap "$wide_gap" padding_top "$wide_top_padding" padding_bottom "$wide_padding" padding_left "$wide_padding" padding_right "$wide_padding" window_placement first_child window_insertion_point first 2>/dev/null

      # Preserve current focus during automatic layout; switch-main.sh handles explicit main changes.
    fi
  fi
else
  set_space_layout stack
  apply_space_settings "normal" second_child focused "$normal_gap" "$normal_top_padding" "$normal_padding" "$normal_padding" "$normal_padding"
  saved_split_ratio=$(layout_state_get "$layout_state_file" split_ratio "$wide_split_ratio")
  valid_ratio "$saved_split_ratio" || saved_split_ratio="$wide_split_ratio"
  saved_solo_ratio=$(layout_state_get "$layout_state_file" solo_ratio "$wide_solo_ratio")
  valid_ratio "$saved_solo_ratio" || saved_solo_ratio="$wide_solo_ratio"
  saved_main_id=$(layout_state_get "$layout_state_file" main_id "")
  layout_state_update "$layout_state_file" mode normal main_id "$saved_main_id" split_ratio "$saved_split_ratio" solo_ratio "$saved_solo_ratio" gap "$normal_gap" padding_top "$normal_top_padding" padding_bottom "$normal_padding" padding_left "$normal_padding" padding_right "$normal_padding" window_placement second_child window_insertion_point focused 2>/dev/null
fi
