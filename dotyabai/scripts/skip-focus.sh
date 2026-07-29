#!/usr/bin/env bash

# Apps to skip when a yabai-initiated space/display switch initially focuses a
# floating/overlay window. Keep this list independent from the yabai manage=off
# ignore list.

set -u
set -o pipefail

readonly SKIP_FOCUS_APPS='Antinote'
readonly SKIP_FOCUS_STATE_DIR="${YABAI_STATE_DIR:-${HOME}/.local/state/yabai}"
readonly SKIP_FOCUS_TOKEN_FILE="${SKIP_FOCUS_STATE_DIR}/skip-focus.token"
readonly SKIP_FOCUS_TOKEN_TTL_SECONDS=1

mark_skip_focus() {
  mkdir -p "${SKIP_FOCUS_STATE_DIR}" 2>/dev/null || return 0
  date +%s >"${SKIP_FOCUS_TOKEN_FILE}" 2>/dev/null || true
}

consume_skip_focus_token() {
  local token_time now age

  [[ -f "${SKIP_FOCUS_TOKEN_FILE}" ]] || return 1

  token_time="$(<"${SKIP_FOCUS_TOKEN_FILE}")"
  rm -f "${SKIP_FOCUS_TOKEN_FILE}" 2>/dev/null || true
  [[ "${token_time}" =~ ^[0-9]+$ ]] || return 1

  now="$(date +%s)"
  [[ "${now}" =~ ^[0-9]+$ ]] || return 1

  age=$((now - token_time))
  ((age >= 0 && age <= SKIP_FOCUS_TOKEN_TTL_SECONDS))
}

skip_focus_apps_json() {
  local skip_app

  while IFS= read -r skip_app; do
    [[ -n "${skip_app}" ]] || continue
    [[ "${skip_app}" == \#* ]] && continue
    printf '%s\n' "${skip_app}"
  done <<<"${SKIP_FOCUS_APPS}" | jq -R . | jq -s .
}

is_skip_focus_app() {
  local app="$1"
  local skip_app

  [[ -n "${app}" ]] || return 1

  while IFS= read -r skip_app; do
    [[ -n "${skip_app}" ]] || continue
    [[ "${skip_app}" == \#* ]] && continue
    [[ "${app}" == "${skip_app}" ]] && return 0
  done <<<"${SKIP_FOCUS_APPS}"

  return 1
}

current_space_index() {
  yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty' 2>/dev/null || true
}

focused_app_name() {
  yabai -m query --windows --window 2>/dev/null | jq -r '.app // empty' 2>/dev/null || true
}

focus_first_allowed_window() {
  local space_index
  local skip_apps_json
  local window_id

  space_index="$(current_space_index)"
  [[ -n "${space_index}" ]] || return 1

  skip_apps_json="$(skip_focus_apps_json)"
  window_id="$(
    yabai -m query --windows --space "${space_index}" 2>/dev/null |
      jq -er --argjson skip_apps "${skip_apps_json}" '
        [
          .[]
          | select(."is-visible" == true)
          | select(."is-minimized" == false)
          | select(."is-hidden" == false)
          | select(."has-ax-reference" == true)
          | select((.app as $app | $skip_apps | index($app)) == null)
        ] as $windows
        | (
            ($windows | map(select(."is-floating" == false)))
            + ($windows | map(select(."is-floating" == true)))
          )[0].id // empty
      ' 2>/dev/null || true
  )"

  [[ -n "${window_id}" && "${window_id}" != "null" ]] || return 1
  yabai -m window --focus "${window_id}"
}

main() {
  case "${1:-run}" in
    mark|--mark)
      mark_skip_focus
      return 0
      ;;
    run|--run)
      ;;
    *)
      printf 'Usage: %s [mark|run]\n' "$(basename "$0")" >&2
      return 2
      ;;
  esac

  consume_skip_focus_token || return 0
  command -v yabai >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0

  if is_skip_focus_app "$(focused_app_name)"; then
    focus_first_allowed_window || true
  fi
}

main "$@"
