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

is_latest_focus_token() {
  local token_file="$1"
  local token="$2"

  [[ -f "${token_file}" ]] && [[ "$(<"${token_file}")" == "${token}" ]]
}

main() {
  local state_dir
  local latest_focus_token_file
  local focus_token
  local window_json
  local open_error
  local window_id
  local window_space_index
  local current_space_index
  local attempt

  (( $# >= 1 )) || {
    usage
    exit 2
  }

  focus_app_name="$*"
  state_dir="${HOME}/.local/state/yabai"
  latest_focus_token_file="${state_dir}/focus-app.latest"
  focus_token="$$-$(date +%s%N)-${focus_app_name}"

  mkdir -p "${state_dir}" 2>/dev/null
  printf '%s\n' "${focus_token}" >"${latest_focus_token_file}"

  command -v yabai >/dev/null 2>&1 || {
    printf '%s\n' "Error: yabai is not available in PATH" >&2
    exit 127
  }
  command -v jq >/dev/null 2>&1 || {
    printf '%s\n' "Error: jq is not available in PATH" >&2
    exit 127
  }

  # Pick the first non-minimized match from yabai's default query order.
  window_json="$(
    yabai -m query --windows |
      jq -cer --arg app "${focus_app_name}" '
        [
          .[]
          | select(.app == $app)
          | select(."is-minimized" == false)
        ][0] // empty
      ' 2>/dev/null || true
  )"

  if [[ -z "${window_json}" ]]; then
    is_latest_focus_token "${latest_focus_token_file}" "${focus_token}" ||
      return 0
    if ! open_error="$(open -a "${focus_app_name}" 2>&1)"; then
      printf '%s\n' "${open_error}" >&2
      notify_error "${open_error}"
      exit 1
    fi
    return 0
  fi

  window_id="$(jq -r '.id' <<<"${window_json}")"
  window_space_index="$(jq -r '.space' <<<"${window_json}")"
  # Window `.space` is the Mission Control index, not the stable space id.
  current_space_index="$(
    yabai -m query --spaces --space |
      jq -r '.index'
  )"

  # Focus the space first to avoid the cross-space window-focus animation.
  if [[
    -n "${window_space_index}" &&
      "${window_space_index}" != "null" &&
      "${window_space_index}" != "${current_space_index}"
  ]]; then
    is_latest_focus_token "${latest_focus_token_file}" "${focus_token}" ||
      return 0
    yabai -m space --focus "${window_space_index}"

    for ((attempt = 0; attempt < 10; attempt += 1)); do
      is_latest_focus_token "${latest_focus_token_file}" "${focus_token}" ||
        return 0
      current_space_index="$(
        yabai -m query --spaces --space |
          jq -r '.index'
      )"
      [[ "${current_space_index}" == "${window_space_index}" ]] && break
      sleep 0.05
    done
  fi

  # macOS may initially focus that space's previously focused window.
  for ((attempt = 0; attempt < 10; attempt += 1)); do
    is_latest_focus_token "${latest_focus_token_file}" "${focus_token}" ||
      return 0
    yabai -m window --focus "${window_id}" || true
    if yabai -m query --windows --window "${window_id}" |
      jq -e '."has-focus" == true' >/dev/null; then
      return 0
    fi
    sleep 0.05
  done

  notify_error "Timed out focusing ${focus_app_name}"
  exit 1
}

trap on_error ERR
main "$@"
