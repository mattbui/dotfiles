#!/usr/bin/env sh

# Display-aware layout:
# - wide displays (aspect >= 2.0): BSP, 12 padding (6 top), 10 gap
#   - one managed window: centered at 65% width
#   - multiple managed windows: 40/60 vertical split, saved main on right, others stacked left
# - normal displays: stack, 8 padding (6 top), 8 gap

wide_threshold="2.0"
wide_solo_ratio="0.65"
wide_split_ratio="0.4"
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

# If another signal arrives while layout is running, mark one pending rerun.
# Releasing the lock also runs that latest request once, avoiding both
# overlapping layout mutations and dropped fast space/window events.
release_layout_lock() {
  status=$?
  trap - EXIT INT TERM
  rmdir "$lock_dir" 2>/dev/null
  if [ -f "$pending_file" ]; then
    rm -f "$pending_file" 2>/dev/null
    "$0" >/dev/null 2>&1 &
  fi
  exit "$status"
}
trap release_layout_lock EXIT INT TERM

require() {
  command -v "$1" >/dev/null 2>&1 || exit 0
}

require yabai
require jq
require awk

# shellcheck source=/dev/null
. "$(dirname "$0")/layout-state.sh"
# shellcheck source=/dev/null
. "$(dirname "$0")/ignore-list.sh"

ignored_apps_json=$(list_ignore 2>/dev/null | jq -R . | jq -s .)

space_json=$(yabai -m query --spaces --space 2>/dev/null) || exit 0
space_index=$(printf '%s' "$space_json" | jq -r '.index')
space_id=$(printf '%s' "$space_json" | jq -r '.id')
space_label=$(printf '%s' "$space_json" | jq -r '.label // empty')
space_type=$(printf '%s' "$space_json" | jq -r '.type')
space_display=$(printf '%s' "$space_json" | jq -r '.display')
[ -n "$space_index" ] && [ "$space_index" != "null" ] || exit 0
[ -n "$space_display" ] && [ "$space_display" != "null" ] || exit 0

# Refresh space labels if missing; fall back to space id for state.
if [ -z "$space_label" ] || [ "$space_label" = "null" ]; then
  "$(dirname "$0")/label-spaces-displays.sh" >/dev/null 2>&1
  space_json=$(yabai -m query --spaces --space "$space_index" 2>/dev/null) || exit 0
  space_label=$(printf '%s' "$space_json" | jq -r '.label // empty')
  space_type=$(printf '%s' "$space_json" | jq -r '.type')
fi

if [ -n "$space_label" ] && [ "$space_label" != "null" ]; then
  layout_state_file=$(layout_state_file_for_space_label "$space_label")
else
  layout_state_file=$(layout_state_file_for_space_label "id-$space_id")
fi

query_candidate_windows() {
  # Only layout visible, managed candidate windows.
  # Ignore floating windows, minimized windows, hidden windows, and apps listed
  # in ~/.local/state/yabai/yabaiignore because they should not influence the
  # main/stack layout decisions.
  yabai -m query --windows --space "$space_index" 2>/dev/null |
    jq --argjson ignored_apps "$ignored_apps_json" '[.[] | .app as $app | select(."is-floating" == false and ."is-minimized" == false and ."is-hidden" == false and (($ignored_apps | index($app)) | not))]'
}

apply_config_if_needed() {
  key="$1"
  desired="$2"
  current=$(yabai -m config --space "$space_index" "$key" 2>/dev/null || printf '')

  if [ "$current" != "$desired" ]; then
    yabai -m config --space "$space_index" "$key" "$desired"
  fi
}

apply_space_settings() {
  mode="$1"
  space_layout="$2"
  placement="$3"
  insertion_point="$4"
  gap="$5"
  top="$6"
  bottom="$7"
  left="$8"
  right="$9"

  if [ "$space_type" != "$space_layout" ]; then
    if yabai -m space "$space_index" --layout "$space_layout"; then
      space_type="$space_layout"
    fi
  fi

  apply_config_if_needed window_placement "$placement"
  apply_config_if_needed window_insertion_point "$insertion_point"
  apply_config_if_needed window_gap "$gap"
  apply_config_if_needed top_padding "$top"
  apply_config_if_needed bottom_padding "$bottom"
  apply_config_if_needed left_padding "$left"
  apply_config_if_needed right_padding "$right"

}

display_json=$(yabai -m query --displays --display "$space_display" 2>/dev/null) || exit 0
[ -n "$display_json" ] || exit 0

display_w=$(printf '%s' "$display_json" | jq -r '.frame.w')
display_h=$(printf '%s' "$display_json" | jq -r '.frame.h')
is_wide=$(awk "BEGIN { print (($display_w / $display_h) >= $wide_threshold) ? 1 : 0 }")

# layout for wide screens
if [ "$is_wide" -eq 1 ]; then
  candidate_windows=$(query_candidate_windows) || exit 0
  candidate_count=$(printf '%s' "$candidate_windows" | jq 'length')

  # with one window, put it in the middle with large padding on both sides
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
    side_padding=$(awk "BEGIN { printf \"%d\", ($display_w * (1 - $saved_solo_ratio) / 2) }")
    apply_space_settings "wide-solo" bsp first_child first "$wide_gap" "$wide_top_padding" "$wide_padding" "$side_padding" "$side_padding"
    saved_split_ratio=$(layout_state_get "$layout_state_file" split_ratio "$wide_split_ratio")
    valid_ratio "$saved_split_ratio" || saved_split_ratio="$wide_split_ratio"
    layout_state_update "$layout_state_file" mode wide-solo space_layout bsp solo_ratio "$saved_solo_ratio" split_ratio "$saved_split_ratio" gap "$wide_gap" padding_top "$wide_top_padding" padding_bottom "$wide_padding" padding_left "$side_padding" padding_right "$side_padding" window_placement first_child window_insertion_point first 2>/dev/null

  # with multiple windows, put one main window on the right, all other windows stack on the left
  elif [ "$candidate_count" -gt 1 ]; then
    apply_space_settings "wide-multi" bsp first_child first "$wide_gap" "$wide_top_padding" "$wide_padding" "$wide_padding" "$wide_padding"

    candidate_windows=$(query_candidate_windows) || exit 0

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
        candidate_windows=$(query_candidate_windows) || exit 0
      fi
    fi

    # Prefer an existing stack member as the left anchor. A newly moved window
    # can briefly be the leftmost unstacked pane; choosing it as anchor would
    # leave the existing stack separate because stacked windows are skipped below.
    anchor_id=$(printf '%s' "$candidate_windows" | jq -r --argjson main "$main_id" '([.[] | select(.id != $main and ."stack-index" > 0)] | sort_by(.frame.x) | first.id) // ([.[] | select(.id != $main)] | sort_by(.frame.x) | first.id) // empty')
    if [ -n "$main_id" ] && [ -n "$anchor_id" ] && [ "$main_id" != "$anchor_id" ]; then
      # Stack every non-main, non-anchor, currently unstacked window onto the left anchor.
      stack_ids=$(printf '%s' "$candidate_windows" | jq -r --argjson main "$main_id" --argjson anchor "$anchor_id" '.[] | select(.id != $main and .id != $anchor and ."stack-index" == 0) | .id')
      if [ -n "$stack_ids" ]; then
        for id in $stack_ids; do
          yabai -m window "$anchor_id" --stack "$id" 2>/dev/null
        done
        candidate_windows=$(query_candidate_windows) || exit 0
      fi

      main_x=$(printf '%s' "$candidate_windows" | jq -r --argjson id "$main_id" '.[] | select(.id == $id) | .frame.x')
      anchor_x=$(printf '%s' "$candidate_windows" | jq -r --argjson id "$anchor_id" '.[] | select(.id == $id) | .frame.x')

      if [ -n "$main_x" ] && [ -n "$anchor_x" ] && awk "BEGIN { exit !($main_x < $anchor_x) }"; then
        if yabai -m window "$main_id" --swap east 2>/dev/null; then
          candidate_windows=$(query_candidate_windows) || exit 0
        fi
      fi

      # Treat the persisted split_ratio as the source of truth. On every
      # apply-layout run, infer the current left/main split from frames and
      # only call --ratio when it differs from the saved target beyond tolerance.
      main_w=$(printf '%s' "$candidate_windows" | jq -r --argjson id "$main_id" '.[] | select(.id == $id) | .frame.w')
      anchor_w=$(printf '%s' "$candidate_windows" | jq -r --argjson id "$anchor_id" '.[] | select(.id == $id) | .frame.w')

      if [ -z "$main_w" ] || [ -z "$anchor_w" ] || ! awk "BEGIN { sum = $anchor_w + $main_w; if (sum <= 0) exit 1; d = ($anchor_w / sum) - $target_split_ratio; if (d < 0) d = -d; exit !(d <= $wide_ratio_tolerance) }"; then
        yabai -m window "$main_id" --ratio abs:"$target_split_ratio" 2>/dev/null
      fi

      layout_state_update "$layout_state_file" mode wide-multi space_layout bsp main_id "$main_id" split_ratio "$target_split_ratio" solo_ratio "$saved_solo_ratio" gap "$wide_gap" padding_top "$wide_top_padding" padding_bottom "$wide_padding" padding_left "$wide_padding" padding_right "$wide_padding" window_placement first_child window_insertion_point first 2>/dev/null
    fi
  fi

# layout for standard screens
else
  apply_space_settings "normal" stack second_child focused "$normal_gap" "$normal_top_padding" "$normal_padding" "$normal_padding" "$normal_padding"
  saved_split_ratio=$(layout_state_get "$layout_state_file" split_ratio "$wide_split_ratio")
  valid_ratio "$saved_split_ratio" || saved_split_ratio="$wide_split_ratio"
  saved_solo_ratio=$(layout_state_get "$layout_state_file" solo_ratio "$wide_solo_ratio")
  valid_ratio "$saved_solo_ratio" || saved_solo_ratio="$wide_solo_ratio"
  saved_main_id=$(layout_state_get "$layout_state_file" main_id "")
  layout_state_update "$layout_state_file" mode normal space_layout stack main_id "$saved_main_id" split_ratio "$saved_split_ratio" solo_ratio "$saved_solo_ratio" gap "$normal_gap" padding_top "$normal_top_padding" padding_bottom "$normal_padding" padding_left "$normal_padding" padding_right "$normal_padding" window_placement second_child window_insertion_point focused 2>/dev/null
fi
