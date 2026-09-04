#!/usr/bin/env bash

# Return one consistent-enough yabai snapshot for the asynchronous bar controller.

set -o pipefail

query_spaces_by_label() {
  local spaces='[]'
  local space
  local number

  for ((number = 1; number <= 32; number += 1)); do
    space="$(
      yabai -m query \
        --spaces id,index,label,display,has-focus,is-visible \
        --space "space-${number}" 2>/dev/null
    )" || break
    jq -e 'type == "object"' <<<"${space}" >/dev/null 2>&1 || break
    spaces="$(
      jq -c --argjson space "${space}" '. + [$space]' <<<"${spaces}"
    )" || return 1
  done

  jq -e 'length > 0' <<<"${spaces}" >/dev/null 2>&1 || return 1
  printf '%s\n' "${spaces}"
}

main() {
  local spaces
  local windows
  local window_fields

  command -v yabai >/dev/null 2>&1 || return 1
  command -v jq >/dev/null 2>&1 || return 1

  spaces="$(
    yabai -m query --spaces id,index,label,display,has-focus,is-visible 2>/dev/null
  )" || return 1
  if ! jq -e 'type == "array"' <<<"${spaces}" >/dev/null 2>&1; then
    spaces="$(query_spaces_by_label)" || return 1
  fi

  window_fields="id,app,role,subrole,space,frame,stack-index,has-focus,is-visible"
  window_fields+=",is-minimized,is-hidden,is-floating,is-sticky"
  windows="$(yabai -m query --windows "${window_fields}" 2>/dev/null)" || return 1
  jq -e 'type == "array"' <<<"${windows}" >/dev/null 2>&1 || return 1

  jq -cn \
    --argjson spaces "${spaces}" \
    --argjson windows "${windows}" \
    '{spaces: $spaces, windows: $windows}'
}

main "$@"
