#!/usr/bin/env bash

# Toggle float modes.
# Usage:
#   toggle-float.sh center [window-id] [toggle|ensure]
#   toggle-float.sh fullscreen [window-id] [toggle|ensure]

set -o pipefail

readonly TOGGLE_FLOAT_CENTER_HEIGHT_RATIO="0.80"
readonly TOGGLE_FLOAT_CENTER_ASPECT_RATIO="1.50"
readonly TOGGLE_FLOAT_CENTER_MAX_WIDTH_RATIO="0.95"
readonly TOGGLE_FLOAT_FULLSCREEN_RATIO="1.00"
readonly TOGGLE_FLOAT_ROOMY_AREA_THRESHOLD="3500000"
readonly TOGGLE_FLOAT_COMPACT_PADDING="8"
readonly TOGGLE_FLOAT_ROOMY_PADDING="12"
readonly TOGGLE_FLOAT_TOP_PADDING="6"
readonly TOGGLE_FLOAT_BOUNDS_TOLERANCE="2"

query_window() {
  local target_window="$1"

  if [[ -n "${target_window}" ]]; then
    yabai -m query --windows --window "${target_window}" 2>/dev/null
  else
    yabai -m query --windows --window 2>/dev/null
  fi
}

toggle_window_float() {
  local target_window="$1"

  if [[ -n "${target_window}" ]]; then
    yabai -m window "${target_window}" --toggle float
  else
    yabai -m window --toggle float
  fi
}

macos_menu_bar_height() {
  command -v osascript >/dev/null 2>&1 || return 1

  osascript -l JavaScript <<'EOF' 2>/dev/null || printf '0'
ObjC.import('AppKit')
const s = $.NSScreen.mainScreen
const f = s.frame
const v = s.visibleFrame
Math.max(0, f.size.height - v.size.height - v.origin.y)
EOF
}

usable_bounds() {
  local mode="$1"
  local window_json="$2"
  local display_id
  local display_json
  local display_width
  local display_height
  local x
  local y
  local width
  local height
  local menu_bar_height="0"
  local reserved_top="0"
  local space_index
  local space_top
  local space_bottom
  local space_left
  local space_right
  local base_padding

  display_id="$(jq -r '.display' <<<"${window_json}")"
  display_json="$(
    yabai -m query --displays --display "${display_id}" 2>/dev/null
  )" || return 1
  [[ -n "${display_json}" ]] || return 1
  display_width="$(jq -r '.frame.w' <<<"${display_json}")"
  display_height="$(jq -r '.frame.h' <<<"${display_json}")"

  # Prefer the constrained frame when yabai exposes one.
  x="$(jq -r '."visible-frame".x // .frame.x' <<<"${display_json}")"
  y="$(jq -r '."visible-frame".y // .frame.y' <<<"${display_json}")"
  width="$(jq -r '."visible-frame".w // .frame.w' <<<"${display_json}")"
  height="$(jq -r '."visible-frame".h // .frame.h' <<<"${display_json}")"

  if [[ "${mode}" == "fullscreen" ]]; then
    menu_bar_height="$(macos_menu_bar_height)" || return 1
    [[ -n "${menu_bar_height}" ]] || menu_bar_height="0"
    reserved_top="${menu_bar_height}"
  fi

  # Apply the current space padding to yabai's constrained display bounds.
  space_index="$(jq -r '.space' <<<"${window_json}")"
  space_top="$(
    yabai -m config --space "${space_index}" top_padding 2>/dev/null ||
      printf '0'
  )"
  space_bottom="$(
    yabai -m config --space "${space_index}" bottom_padding 2>/dev/null ||
      printf '0'
  )"
  space_left="$(
    yabai -m config --space "${space_index}" left_padding 2>/dev/null ||
      printf '0'
  )"
  space_right="$(
    yabai -m config --space "${space_index}" right_padding 2>/dev/null ||
      printf '0'
  )"

  # Centered single-stack padding should not constrain a fullscreen float.
  if [[ "${mode}" == "fullscreen" ]]; then
    base_padding="$(
      awk \
        -v width="${display_width}" \
        -v height="${display_height}" \
        -v threshold="${TOGGLE_FLOAT_ROOMY_AREA_THRESHOLD}" \
        -v compact="${TOGGLE_FLOAT_COMPACT_PADDING}" \
        -v roomy="${TOGGLE_FLOAT_ROOMY_PADDING}" '
          BEGIN {
            print ((width * height) >= threshold) ? roomy : compact
          }
        '
    )"
    space_top="${TOGGLE_FLOAT_TOP_PADDING}"
    space_bottom="${base_padding}"
    space_left="${base_padding}"
    space_right="${base_padding}"
  fi

  awk \
    -v x="${x}" \
    -v y="${y}" \
    -v width="${width}" \
    -v height="${height}" \
    -v reserved_top="${reserved_top}" \
    -v top="${space_top}" \
    -v bottom="${space_bottom}" \
    -v left="${space_left}" \
    -v right="${space_right}" '
      BEGIN {
        x += left
        y += reserved_top + top
        width -= left + right
        height -= reserved_top + top + bottom
        if (width < 1) {
          width = 1
        }
        if (height < 1) {
          height = 1
        }
        printf "%d %d %d %d\n", x, y, width, height
      }
    '
}

target_bounds() {
  local mode="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"

  if [[ "${mode}" == "fullscreen" ]]; then
    awk \
      -v x="${x}" \
      -v y="${y}" \
      -v width="${width}" \
      -v height="${height}" \
      -v ratio="${TOGGLE_FLOAT_FULLSCREEN_RATIO}" '
        BEGIN {
          target_width = width * ratio
          target_height = height * ratio
          target_x = x + ((width - target_width) / 2)
          target_y = y + ((height - target_height) / 2)
          printf "%d %d %d %d\n",
            target_x,
            target_y,
            target_width,
            target_height
        }
      '
  else
    awk \
      -v x="${x}" \
      -v y="${y}" \
      -v width="${width}" \
      -v height="${height}" \
      -v height_ratio="${TOGGLE_FLOAT_CENTER_HEIGHT_RATIO}" \
      -v aspect_ratio="${TOGGLE_FLOAT_CENTER_ASPECT_RATIO}" \
      -v max_width_ratio="${TOGGLE_FLOAT_CENTER_MAX_WIDTH_RATIO}" '
        BEGIN {
          target_height = height * height_ratio
          target_width = target_height * aspect_ratio
          maximum_width = width * max_width_ratio
          if (target_width > maximum_width) {
            target_width = maximum_width
          }
          target_x = x + ((width - target_width) / 2)
          target_y = y + ((height - target_height) / 2)
          printf "%d %d %d %d\n",
            target_x,
            target_y,
            target_width,
            target_height
        }
      '
  fi
}

window_matches_bounds() {
  local window_json="$1"
  local x="$2"
  local y="$3"
  local width="$4"
  local height="$5"

  jq -e \
    --argjson x "${x}" \
    --argjson y "${y}" \
    --argjson width "${width}" \
    --argjson height "${height}" \
    --argjson tolerance "${TOGGLE_FLOAT_BOUNDS_TOLERANCE}" '
      def difference($actual; $desired):
        ($actual - $desired) as $difference
        | if $difference < 0 then -$difference else $difference end;

      difference(.frame.x; $x) <= $tolerance
      and difference(.frame.y; $y) <= $tolerance
      and difference(.frame.w; $width) <= $tolerance
      and difference(.frame.h; $height) <= $tolerance
    ' <<<"${window_json}" >/dev/null
}

apply_bounds() {
  local mode="$1"
  local target_window="$2"
  local x="$3"
  local y="$4"
  local width="$5"
  local height="$6"
  local -a window_command=(yabai -m window)

  [[ -n "${target_window}" ]] && window_command+=("${target_window}")

  # Fullscreen moves first because resizing at a padded x position can clamp.
  if [[ "${mode}" == "fullscreen" ]]; then
    "${window_command[@]}" --move abs:"${x}":"${y}"
    sleep 0.01 # Wait for JankyBorders to render correctly.
    "${window_command[@]}" --resize abs:"${width}":"${height}"
    "${window_command[@]}" --move abs:"${x}":"${y}"
  else
    # Resize first so JankyBorders does not render an old-size border at the
    # final floated position.
    "${window_command[@]}" --resize abs:"${width}":"${height}"
    "${window_command[@]}" --move abs:"${x}":"${y}"
  fi
}

main() {
  local mode="${1:-center}"
  local target_window="${2:-}"
  local float_action="${3:-toggle}"
  local apply_layout_script="${YABAI_APPLY_LAYOUT_SCRIPT:-}"
  local window_json
  local initially_floating
  local x
  local y
  local width
  local height

  if [[ -z "${apply_layout_script}" ]]; then
    apply_layout_script="${HOME}/.config/yabai/scripts/apply-layout.sh"
  fi

  case "${mode}" in
    center|fullscreen) ;;
    *) return 1 ;;
  esac
  case "${float_action}" in
    toggle|ensure) ;;
    *) return 1 ;;
  esac

  command -v yabai >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0
  command -v awk >/dev/null 2>&1 || return 0

  window_json="$(query_window "${target_window}")" || return 0
  [[ -n "${window_json}" ]] || return 0
  initially_floating="$(jq -r '."is-floating"' <<<"${window_json}")"

  read -r x y width height < <(usable_bounds "${mode}" "${window_json}") ||
    return 0
  read -r x y width height < <(
    target_bounds "${mode}" "${x}" "${y}" "${width}" "${height}"
  ) || return 0

  # currently window is already floating and in the desired bounds
  # toggle -> unfloat it and apply layout
  if [[ "${initially_floating}" == "true" && "${float_action}" == "toggle" ]] &&
    window_matches_bounds \
      "${window_json}" \
      "${x}" \
      "${y}" \
      "${width}" \
      "${height}"; then
    toggle_window_float "${target_window}" || return 0
    "${apply_layout_script}"
    return 0
  fi

  # not already floating -> float it and update current window_json
  if [[ "${initially_floating}" != "true" ]]; then
    toggle_window_float "${target_window}" || return 0
    window_json="$(query_window "${target_window}")" || return 0
    [[ -n "${window_json}" ]] || return 0

    # still tiled -> apply layout
    if ! jq -e '."is-floating" == true' <<<"${window_json}" >/dev/null; then
      "${apply_layout_script}"
      return 0
    fi
  fi

  # floated -> resize and move to the desired bounds
  apply_bounds \
    "${mode}" \
    "${target_window}" \
    "${x}" \
    "${y}" \
    "${width}" \
    "${height}"

  if [[ "${mode}" == "center" ]]; then
    "${apply_layout_script}"
  fi
}

main "$@"
