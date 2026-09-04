#!/usr/bin/env bash

# Focus an existing application window or open the application.
# Usage: focus-app.sh <application-name>

set -Eeuo pipefail

focus_app_name=""

notify_error() {
  local message="$1"
  local escaped_message

  command -v osascript >/dev/null 2>&1 || return 0
  escaped_message="$(printf '%s' "${message}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  osascript <<EOF >/dev/null 2>&1
display notification "${escaped_message}" with title "yabai" subtitle "Focus App Error"
EOF
}

on_error() {
  local status=$?

  notify_error \
    "Failed to focus/open ${focus_app_name:-unknown app} (exit ${status})"
}

usage() {
  printf 'Usage: %s <application-name>\n' "$(basename "$0")" >&2
  printf 'Example: %s Safari\n' "$(basename "$0")" >&2
}

main() {
  local window_json
  local open_error
  local window_id

  (( $# >= 1 )) || {
    usage
    exit 2
  }

  focus_app_name="$*"

  command -v yabai >/dev/null 2>&1 || {
    printf '%s\n' "Error: yabai is not available in PATH" >&2
    exit 127
  }
  command -v jq >/dev/null 2>&1 || {
    printf '%s\n' "Error: jq is not available in PATH" >&2
    exit 127
  }

  # Cycle through ordinary application windows in stable window-id order. Do
  # not require is-visible: yabai reports windows on inactive spaces as not
  # visible on the current display even when they are otherwise focusable.
  window_json="$(
    yabai -m query --windows |
      jq -cer --arg app "${focus_app_name}" '
        [
          .[]
          | select(.app == $app)
          | select(.id > 0 and .space > 0)
          | select(.scratchpad == "")
          | select(.role == "AXWindow")
          | select(.subrole == "AXStandardWindow")
          | select(."has-ax-reference" == true)
          | select(."is-minimized" == false)
          | select(."is-hidden" == false)
          | select(."is-sticky" == false)
          | select(."is-grabbed" == false)
        ]
        | sort_by(.id) as $windows
        | ($windows | map(."has-focus") | index(true)) as $focused_index
        | if ($windows | length) == 0 then
            empty
          elif $focused_index == null then
            $windows[0]
          else
            $windows[(($focused_index + 1) % ($windows | length))]
          end
      ' 2>/dev/null || true
  )"

  if [[ -z "${window_json}" ]]; then
    if ! open_error="$(open -a "${focus_app_name}" 2>&1)"; then
      printf '%s\n' "${open_error}" >&2
      notify_error "${open_error}"
      exit 1
    fi
    return 0
  fi

  window_id="$(jq -r '.id' <<<"${window_json}")"
  yabai -m window --focus "${window_id}"
}

trap on_error ERR
main "$@"
