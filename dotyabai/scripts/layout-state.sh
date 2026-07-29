#!/usr/bin/env bash

# Helpers for per-space dotyabai JSON layout state files.
# Do not source state files.
# LAYOUT_STATE_ROOT is provided by layout-lib.sh.
# shellcheck disable=SC2154

layout_state_file_for_space_label() {
  # Use the yabai space label for per-space layout state.
  # Example: space-1 -> layout-space-1.json
  printf '%s/layout-%s.json' "${LAYOUT_STATE_ROOT}" "$1"
}

# Reads a valid state object once, defaulting to an empty object.
layout_state_read() {
  local file="$1"
  local state

  if [[ -n "${file}" && -f "${file}" ]]; then
    if state="$(
      jq -ce 'if type == "object" then . else empty end' "${file}" 2>/dev/null
    )"; then
      printf '%s' "${state}"
      return
    fi
  fi

  printf '{}'
}

layout_state_json_set() {
  local src="$1"
  local dst="$2"
  local key="$3"
  local value="$4"

  jq \
    --arg key "${key}" \
    --arg value "${value}" \
    '.[$key] = ($value | tonumber? // $value)' \
    "${src}" >"${dst}"
}

layout_state_update() {
  local file="$1"
  local dir
  local tmp
  local next

  shift

  dir="$(dirname "${file}")"
  mkdir -p "${dir}" 2>/dev/null || return 1
  tmp="${file}.$$"
  next="${file}.$$.next"

  if [[ -f "${file}" ]] && jq -e . "${file}" >/dev/null 2>&1; then
    cp "${file}" "${tmp}" || return 1
  else
    printf '{}\n' >"${tmp}" || return 1
  fi

  while (( $# > 1 )); do
    if layout_state_json_set "${tmp}" "${next}" "$1" "$2"; then
      mv "${next}" "${tmp}"
    else
      rm -f "${tmp}" "${next}"
      return 1
    fi
    shift 2
  done

  if [[ -f "${file}" ]] && cmp -s "${tmp}" "${file}"; then
    rm -f "${tmp}"
    return 0
  fi

  mv "${tmp}" "${file}"
}
