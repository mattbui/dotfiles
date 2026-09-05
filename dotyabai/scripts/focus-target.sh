#!/usr/bin/env bash

# Coordinate focus requests so temporary animation skipping for window shortcuts
# and bar clicks does not cause cross-display space switches to jump to the wrong space.
# Newer requests supersede older work; cleanup restores animation skipping to off.
#
# Usage: focus-target.sh [--keep-mouse] window ID [space-index [true|false|unknown]]
#        focus-target.sh space|display selector
#        focus-target.sh move-space|move-display window-selector destination.
set -o pipefail

readonly FOCUS_STATE_DIR="${YABAI_STATE_DIR:-${HOME}/.local/state/yabai}/focus"
# The latest token lets newer shortcuts cancel older queued work.
readonly LATEST_FOCUS_REQUEST="${FOCUS_STATE_DIR}/request"
# State file paths. Each token identifies the request that owns its temporary override.
readonly MOUSE_OVERRIDE_TOKEN="${FOCUS_STATE_DIR}/mouse-override-token"
# Save the prior on/off value for cleanup after that request.
readonly MOUSE_FOLLOWS_FOCUS_VALUE="${FOCUS_STATE_DIR}/mouse-follows-focus-value"
# Older cleanup must not disable animation skipping enabled by a newer request.
readonly ANIMATION_SKIP_OVERRIDE_TOKEN="${FOCUS_STATE_DIR}/animation-skip-override-token"

# Lock files carry no request data. fd 8 serializes token publication; fd 9 prevents
# focus commands and animation-setting changes from overlapping.
readonly REQUEST_PUBLICATION_LOCK="${FOCUS_STATE_DIR}/request.lock"
readonly FOCUS_DISPATCH_LOCK="${FOCUS_STATE_DIR}/lock"

focus_request_is_latest() {
  [[ -f "${LATEST_FOCUS_REQUEST}" && "$(<"${LATEST_FOCUS_REQUEST}")" == "$1" ]]
}

# Require fd 9's lock so cleanup cannot race a newer request enabling skipping.
# The ownership file avoids a redundant config command when skipping is already off.
disable_animation_skip() {
  [[ -s "${ANIMATION_SKIP_OVERRIDE_TOKEN}" ]] || return 0
  yabai -m config skip_window_focus_animation off || return 1
  : >"${ANIMATION_SKIP_OVERRIDE_TOKEN}"
}

# All temporary settings share the dispatch lock and request ownership.
restore_mouse_follows_focus() {
  [[ -s "${MOUSE_OVERRIDE_TOKEN}" ]] || return 0
  local previous
  previous="$(<"${MOUSE_FOLLOWS_FOCUS_VALUE}")"
  case "${previous}" in on|off) ;; *) return 1 ;; esac
  yabai -m config mouse_follows_focus "${previous}" || return 1
  : >"${MOUSE_OVERRIDE_TOKEN}"
}

clear_temporary_focus_overrides() {
  local status=0
  disable_animation_skip || status=1
  restore_mouse_follows_focus || status=1
  return "${status}"
}

# Background cleanup must reacquire the lock and leave a newer request's toggle alone.
clear_owned_focus_overrides() {
  local request_token="$1"
  exec 9>"${FOCUS_DISPATCH_LOCK}"
  /usr/bin/lockf -t 5 9 || return 1
  if [[ -f "${ANIMATION_SKIP_OVERRIDE_TOKEN}"
    && "$(<"${ANIMATION_SKIP_OVERRIDE_TOKEN}")" == "${request_token}" ]]; then
    disable_animation_skip
  fi
  if [[ -f "${MOUSE_OVERRIDE_TOKEN}"
    && "$(<"${MOUSE_OVERRIDE_TOKEN}")" == "${request_token}" ]]; then
    restore_mouse_follows_focus
  fi
}

wait_for_focus_and_cleanup() {
  local request_token="$1" target_window_id="$2"
  local attempt focused_window_json consecutive_focus_matches=0
  # A slow focus query must not delay the next shortcut, so release the inherited lock.
  exec 9>&-
  # Expand the request token now so EXIT cleanup keeps the owner after this local scope ends.
  # shellcheck disable=SC2064
  trap "clear_owned_focus_overrides '${request_token}'" EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  # One focus observation may be transient; repeated matches reduce early restoration.
  # Limit attempts so repeated nonmatching results eventually trigger cleanup.
  for ((attempt = 0; attempt < 24; attempt += 1)); do
    focus_request_is_latest "${request_token}" || return 0
    focused_window_json="$(yabai -m query --windows id --window 2>/dev/null)" || focused_window_json='null'
    if jq -e --arg id "${target_window_id}" '.id == ($id | tonumber)' \
      <<<"${focused_window_json}" >/dev/null 2>&1; then
      consecutive_focus_matches=$((consecutive_focus_matches + 1))
      ((consecutive_focus_matches >= 3)) && return 0
    else
      consecutive_focus_matches=0
    fi
    sleep 0.025
  done
}

resolve_target_space_visibility() {
  local target_window_id="$1" space_index="${2:-}" target_space_visible="${3:-unknown}"
  if [[ "${target_space_visible}" == true || "${target_space_visible}" == false ]]; then
    printf '%s\n' "${target_space_visible}"
    return
  fi
  if [[ -z "${space_index}" ]]; then
    space_index="$(yabai -m query --windows space --window "${target_window_id}" |
      jq -er '.space')" || return 1
  fi
  yabai -m query --spaces is-visible --space "${space_index}" |
    jq -er '."is-visible" | tostring'
}

main() {
  local keep_mouse=false previous_mouse_follows_focus
  if [[ "${1:-}" == --keep-mouse ]]; then
    keep_mouse=true
    shift
  fi
  local mode="${1:-}" selector="${2:-}" target_space_visible=false request_token
  local status=0
  case "${mode}" in
    window)
      [[ "${selector}" =~ ^[1-9][0-9]*$ ]] || return 2
      [[ -z "${3:-}" || "$3" =~ ^[1-9][0-9]*$ ]] || return 2
      case "${4:-unknown}" in true|false|unknown) ;; *) return 2 ;; esac ;;
    space|display) [[ -n "${selector}" ]] || return 2 ;;
    move-space|move-display) [[ -n "${selector}" && -n "${3:-}" ]] || return 2 ;;
    *) printf 'Invalid focus target: %s\n' "${mode}" >&2; return 2 ;;
  esac

  [[ -d "${FOCUS_STATE_DIR}" ]] || mkdir -p "${FOCUS_STATE_DIR}" || return 1
  # Distinguish overlapping requests without adding process launches before focus.
  request_token="${BASHPID}-${EPOCHREALTIME}"
  # A separate lock lets new shortcuts supersede work while dispatch is still busy.
  exec 8>"${REQUEST_PUBLICATION_LOCK}"
  /usr/bin/lockf -t 5 8 || return 1
  printf '%s\n' "${request_token}" >"${LATEST_FOCUS_REQUEST}" || return 1
  exec 8>&-

  if [[ "${mode}" == window ]]; then
    target_space_visible="$(
      resolve_target_space_visibility "${selector}" "${3:-}" "${4:-unknown}"
    )" || return 1
  fi

  # Discard stale requests
  exec 9>"${FOCUS_DISPATCH_LOCK}"
  /usr/bin/lockf -t 5 9 || return 1
  focus_request_is_latest "${request_token}" || return 0
  clear_temporary_focus_overrides || return 1
  trap clear_temporary_focus_overrides EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM

  if [[ "${keep_mouse}" == true && "${mode}" == window ]]; then
    previous_mouse_follows_focus="$(yabai -m config mouse_follows_focus)" || return 1
    case "${previous_mouse_follows_focus}" in on|off) ;; *) return 1 ;; esac
    printf '%s\n' "${previous_mouse_follows_focus}" >"${MOUSE_FOLLOWS_FOCUS_VALUE}" || return 1
    printf '%s\n' "${request_token}" >"${MOUSE_OVERRIDE_TOKEN}" || return 1
    yabai -m config mouse_follows_focus off || return 1
  fi

  # Only need to enable skip_window_focus_animation if the target window is in a non visible space
  if [[ "${mode}" == window && "${target_space_visible}" == false ]]; then
    printf '%s\n' "${request_token}" >"${ANIMATION_SKIP_OVERRIDE_TOKEN}" || return 1
    yabai -m config skip_window_focus_animation on || return 1
  fi

  focus_request_is_latest "${request_token}" || return 0
  case "${mode}" in
    window) yabai -m window --focus "${selector}" || status=$? ;;
    space|display)
      yabai -m "${mode}" --focus "${selector}" || status=$? ;;
    move-space|move-display)
      yabai -m window "${selector}" "--${mode#move-}" "$3" || return 1
      focus_request_is_latest "${request_token}" || return 0
      yabai -m "${mode#move-}" --focus "$3" || status=$? ;;
  esac

  if [[ "${mode}" == window && "${status}" == 0
    && ( "${target_space_visible}" == false || "${keep_mouse}" == true ) ]]; then
    wait_for_focus_and_cleanup "${request_token}" "${selector}" \
      </dev/null >/dev/null 2>&1 &
    # Restoring on this process's exit would turn skipping off before focus settles.
    # Leave cleanup to the watcher or the next request instead.
    trap - EXIT INT TERM
  fi
  return "${status}"
}

main "$@"
