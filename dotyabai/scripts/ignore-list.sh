#!/usr/bin/env bash

# Manage dotyabai's yabai ignore list.
# Sourceable functions:
#   ignore_add "AppName"
#   ignore_remove "AppName"
#   ignore_toggle "AppName"
#   ignore_list
#   ignore_has "AppName"
#   ignore_rule_label "AppName"
#   ignore_app_regex "AppName"
# CLI:
#   ignore-list.sh add "AppName"
#   ignore-list.sh remove "AppName"
#   ignore-list.sh toggle "AppName"
#   ignore-list.sh list

readonly IGNORE_STATE_DIR="${YABAI_STATE_DIR:-${HOME}/.local/state/yabai}"
readonly IGNORE_FILE="${IGNORE_STATE_DIR}/yabaiignore"

readonly IGNORE_DEFAULTS='System Settings
Finder
Ghostty
Spark Desktop
Raycast
Raycast Beta
Homerow
Calculator
Keybase
1Password
Zalo
Spotify
Cloudflare WARP
Messages
Find My
Calendar
Karabiner-Elements
Karabiner-EventViewer
Logi Options+
AppCleaner
Activity Monitor
App Store
Disk Utility
Notes
Preview
qlmanage
DockDoor
Antinote'

ignore_ensure_file() {
  mkdir -p "${IGNORE_STATE_DIR}" 2>/dev/null || return 1

  if [[ ! -f "${IGNORE_FILE}" ]]; then
    printf '%s\n' "${IGNORE_DEFAULTS}" |
      sed '/^[[:space:]]*$/d' >"${IGNORE_FILE}"
  fi
}

ignore_normalize_file() {
  local tmp="${IGNORE_FILE}.$$"

  ignore_ensure_file || return 1
  awk 'NF && !seen[$0]++ { print }' "${IGNORE_FILE}" >"${tmp}" &&
    mv "${tmp}" "${IGNORE_FILE}"
}

ignore_list() {
  ignore_ensure_file || return 1
  sed '/^[[:space:]]*$/d' "${IGNORE_FILE}"
}

ignore_has() {
  local app="$1"

  ignore_ensure_file || return 1
  grep -Fx -- "${app}" "${IGNORE_FILE}" >/dev/null 2>&1
}

ignore_add() {
  local app="$1"

  [[ -n "${app}" ]] || return 1
  ignore_ensure_file || return 1

  if ignore_has "${app}"; then
    return 0
  fi

  printf '%s\n' "${app}" >>"${IGNORE_FILE}"
  ignore_normalize_file
}

ignore_remove() {
  local app="$1"
  local tmp="${IGNORE_FILE}.$$"

  [[ -n "${app}" ]] || return 1
  ignore_ensure_file || return 1
  grep -Fvx -- "${app}" "${IGNORE_FILE}" >"${tmp}" || :
  mv "${tmp}" "${IGNORE_FILE}"
}

ignore_toggle() {
  local app="$1"

  [[ -n "${app}" ]] || return 1

  if ignore_has "${app}"; then
    ignore_remove "${app}"
    return 2
  fi

  ignore_add "${app}"
  return 0
}

ignore_rule_label() {
  # Keep labels readable, but avoid spaces so CLI remove/apply is predictable.
  printf 'ignore-%s' "$(printf '%s' "$1" | sed 's/[[:space:]]\{1,\}/-/g')"
}

ignore_app_regex() {
  # Escape extended-regex metacharacters, then anchor exact app name.
  # shellcheck disable=SC2016
  printf '^%s$' "$(printf '%s' "$1" | sed 's/[.[\*^$()+?{}|\\]/\\&/g')"
}

ignore_apply_rule_live() {
  local app="$1"
  local label
  local regex
  local window_ids
  local script_dir
  local toggle_float_script="${YABAI_TOGGLE_FLOAT_SCRIPT:-}"
  local id

  command -v yabai >/dev/null 2>&1 || return 0

  label="$(ignore_rule_label "${app}")"
  regex="$(ignore_app_regex "${app}")"

  # Capture tiled windows before applying manage=off. After rule apply, yabai may
  # already report these unmanaged windows as floating, which would make us skip
  # centering them.
  command -v jq >/dev/null 2>&1 || return 0
  window_ids="$(
    yabai -m query --windows 2>/dev/null |
      jq -r --arg app "${app}" '
        .[]
        | select(.app == $app and ."is-floating" == false)
        | .id
      '
  )"

  yabai -m rule --remove "${label}" >/dev/null 2>&1 || :
  yabai -m rule --add \
    label="${label}" \
    app="${regex}" \
    manage=off >/dev/null 2>&1 || return 0
  yabai -m rule --apply "${label}" >/dev/null 2>&1 || :

  # If this app is now ignored, make windows that were tiled before manage=off
  # float before the next layout apply so they are visually removed from the
  # managed layout. Center them using the regular float helper instead of
  # leaving them at their tiled size/position.
  script_dir="$(dirname "${BASH_SOURCE[0]}")"
  if [[ -n "${toggle_float_script}" && -x "${toggle_float_script}" ]]; then
    :
  elif [[ -x "${script_dir}/toggle-float.sh" ]]; then
    toggle_float_script="${script_dir}/toggle-float.sh"
  elif [[ -x "${HOME}/.config/yabai/scripts/toggle-float.sh" ]]; then
    toggle_float_script="${HOME}/.config/yabai/scripts/toggle-float.sh"
  fi

  while IFS= read -r id; do
    [[ -n "${id}" ]] || continue
    if [[ -n "${toggle_float_script}" ]]; then
      "${toggle_float_script}" center "${id}" ensure >/dev/null 2>&1 || :
    else
      yabai -m window "${id}" --toggle float >/dev/null 2>&1 || :
    fi
  done <<<"${window_ids}"
}

ignore_remove_rule_live() {
  local app="$1"
  local label
  local window_ids
  local id

  command -v yabai >/dev/null 2>&1 || return 0

  label="$(ignore_rule_label "${app}")"
  yabai -m rule --remove "${label}" >/dev/null 2>&1 || :

  # If this app was unmanaged through manage=off, its existing windows may
  # still be floating after the rule is removed. Turn float off before the next
  # layout apply so yabai can include them again.
  command -v jq >/dev/null 2>&1 || return 0
  window_ids="$(
    yabai -m query --windows 2>/dev/null |
      jq -r --arg app "${app}" '
        .[]
        | select(.app == $app and ."is-floating" == true)
        | .id
      '
  )"

  while IFS= read -r id; do
    [[ -n "${id}" ]] || continue
    yabai -m window "${id}" --toggle float >/dev/null 2>&1 || :
  done <<<"${window_ids}"
}

ignore_notify() {
  local subtitle="$1"
  local message="$2"
  local escaped_subtitle
  local escaped_message

  command -v osascript >/dev/null 2>&1 || return 0

  escaped_message="$(printf '%s' "${message}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  escaped_subtitle="$(printf '%s' "${subtitle}" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  osascript <<EOF >/dev/null 2>&1
display notification "${escaped_message}" with title "yabai" subtitle "${escaped_subtitle}"
EOF
}

ignore_run_apply_layout() {
  local script_dir
  local apply_layout_script="${YABAI_APPLY_LAYOUT_SCRIPT:-}"

  script_dir="$(dirname "${BASH_SOURCE[0]}")"
  if [[ -n "${apply_layout_script}" && -x "${apply_layout_script}" ]]; then
    "${apply_layout_script}" >/dev/null 2>&1 &
  elif [[ -x "${script_dir}/apply-layout.sh" ]]; then
    "${script_dir}/apply-layout.sh" >/dev/null 2>&1 &
  elif [[ -x "${HOME}/.config/yabai/scripts/apply-layout.sh" ]]; then
    "${HOME}/.config/yabai/scripts/apply-layout.sh" >/dev/null 2>&1 &
  fi
}

ignore_usage() {
  printf '%s\n' \
    'usage: ignore-list.sh add "AppName"' \
    '       ignore-list.sh remove "AppName"' \
    '       ignore-list.sh toggle "AppName"' \
    '       ignore-list.sh list'
}

ignore_main() {
  local command="${1:-}"
  local app="${2:-}"

  case "${command}" in
    add)
      [[ -n "${app}" ]] || {
        ignore_usage >&2
        return 1
      }
      if ignore_has "${app}"; then
        ignore_notify "Ignore unchanged" "${app} already ignored"
      else
        ignore_add "${app}"
        ignore_apply_rule_live "${app}"
        ignore_notify "Ignore added" "${app}"
      fi
      ;;
    remove)
      [[ -n "${app}" ]] || {
        ignore_usage >&2
        return 1
      }
      if ignore_has "${app}"; then
        ignore_remove "${app}"
        ignore_remove_rule_live "${app}"
        ignore_notify "Ignore removed" "${app}"
      else
        ignore_notify "Ignore unchanged" "${app} was not ignored"
      fi
      ;;
    toggle)
      [[ -n "${app}" ]] || {
        ignore_usage >&2
        return 1
      }
      if ignore_has "${app}"; then
        ignore_remove "${app}"
        ignore_remove_rule_live "${app}"
        ignore_notify "Ignore removed" "${app}"
      else
        ignore_add "${app}"
        ignore_apply_rule_live "${app}"
        ignore_notify "Ignore added" "${app}"
      fi
      ignore_run_apply_layout
      ;;
    list)
      ignore_list
      ;;
    *)
      ignore_usage >&2
      return 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  ignore_main "$@"
fi
