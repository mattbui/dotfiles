#!/usr/bin/env bash

# Query one yabai window for the rare window_focused cache miss.

set -o pipefail

main() {
  local window_id="${1:-}"

  command -v yabai >/dev/null 2>&1 || return 1
  if [[ -z "${window_id}" ]]; then
    yabai -m query --windows --window 2>/dev/null
    return
  fi

  [[ "${window_id}" =~ ^[1-9][0-9]*$ ]] || return 1
  yabai -m query --windows --window "${window_id}" 2>/dev/null
}

main "$@"
