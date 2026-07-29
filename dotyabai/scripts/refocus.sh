#!/usr/bin/env bash

# Restore focus after close/Cmd-W by focusing a visible window on the current space.

set -u
set -o pipefail

macos_front_app() {
  command -v osascript >/dev/null 2>&1 || return 0

  osascript <<'EOF' 2>/dev/null || true
tell application "System Events"
  set frontApps to name of application processes whose frontmost is true
  if (count of frontApps) > 0 then return item 1 of frontApps
end tell
EOF
}

current_space_index() {
  yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty' 2>/dev/null || true
}

focused_window_json() {
  yabai -m query --windows --window 2>/dev/null || printf 'null\n'
}

is_usable_window_json() {
  jq -e '
    . != null
    and ."is-visible" == true
    and ."is-minimized" == false
    and ."is-hidden" == false
    and ."has-ax-reference" == true
  ' >/dev/null 2>&1 <<<"$1"
}

front_app_usable_window_id() {
  local front_app="$1"
  local space_index="$2"
  local app_lower

  [[ -n "${front_app}" && -n "${space_index}" ]] || return 1
  app_lower="$(printf '%s' "${front_app}" | tr '[:upper:]' '[:lower:]')"

  yabai -m query --windows --space "${space_index}" 2>/dev/null |
    jq -er --arg app_lower "${app_lower}" '
      [
        .[]
        | select((.app | ascii_downcase) == $app_lower)
        | select(."is-visible" == true)
        | select(."is-minimized" == false)
        | select(."is-hidden" == false)
        | select(."has-ax-reference" == true)
      ]
      | (
          (
            map(select(."is-floating" == false))
            + map(select(."is-floating" == true))
          )[0].id // empty
        )
    ' 2>/dev/null || true
}

fallback_window_id() {
  local space_index="$1"
  local front_app="$2"
  local app_lower

  [[ -n "${space_index}" ]] || return 1
  app_lower="$(printf '%s' "${front_app}" | tr '[:upper:]' '[:lower:]')"

  yabai -m query --windows --space "${space_index}" 2>/dev/null |
    jq -er --arg app_lower "${app_lower}" '
      [
        .[]
        | select(."is-visible" == true)
        | select(."is-minimized" == false)
        | select(."is-hidden" == false)
        | select(."has-ax-reference" == true)
        | select((.app | ascii_downcase) != $app_lower)
      ]
      | (
          (
            map(select(."is-floating" == false))
            + map(select(."is-floating" == true))
          )[0].id // empty
        )
    ' 2>/dev/null || true
}

try_refocus_once() {
  local front_app
  local space_index
  local focused_json
  local front_window_id
  local candidate_id

  front_app="$(macos_front_app)"
  space_index="$(current_space_index)"
  [[ -n "${space_index}" ]] || return 1

  focused_json="$(focused_window_json)"
  if is_usable_window_json "${focused_json}"; then
    return 0
  fi

  # If the front app still has another real visible window, keep focus there.
  front_window_id="$(
    front_app_usable_window_id "${front_app}" "${space_index}"
  )"
  if [[ -n "${front_window_id}" && "${front_window_id}" != "null" ]]; then
    yabai -m window --focus "${front_window_id}" >/dev/null 2>&1 ||
      return 1
    return 0
  fi

  candidate_id="$(fallback_window_id "${space_index}" "${front_app}")"
  [[ -n "${candidate_id}" && "${candidate_id}" != "null" ]] || return 1

  yabai -m window --focus "${candidate_id}" >/dev/null 2>&1
}

main() {
  local delay

  command -v yabai >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0

  for delay in 0.05 0.10 0.20 0.40; do
    sleep "${delay}"
    try_refocus_once && return 0
  done

  return 0
}

main "$@"
