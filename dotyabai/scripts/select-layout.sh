#!/usr/bin/env bash

# Directly select the current labeled space's flexible layout.
# Usage: select-layout.sh single-stack|two-stack

# shellcheck source=layout-lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/layout-lib.sh"

notify_layout_mode() {
  local mode="$1"
  local message

  command -v osascript >/dev/null 2>&1 || return 0
  case "${mode}" in
    single-stack) message="Single stack" ;;
    two-stack) message="Two stacks" ;;
    *) return 0 ;;
  esac
  osascript \
    -e "display notification \"${message}\" with title \"yabai\" subtitle \"Layout\"" \
    >/dev/null 2>&1
}

main() {
  local requested_mode="${1:-}"
  local area_change_pending=false
  local display_profile
  local preferences

  case "${requested_mode}" in
    single-stack|two-stack) ;;
    *) return 1 ;;
  esac

  layout_require_commands || return 0
  layout_space_json="$(layout_query_space)" || return 0
  layout_space_index="$(jq -r '.index // empty' <<<"${layout_space_json}")"
  layout_space_label="$(jq -r '.label // empty' <<<"${layout_space_json}")"
  layout_space_display_index="$(jq -r '.display // empty' <<<"${layout_space_json}")"
  [[ -n "${layout_space_index}" && -n "${layout_space_display_index}" ]] || return 0
  layout_state_file="$(
    layout_state_file_for_label "${layout_space_label}"
  )"

  layout_display_json="$(
    layout_query_display "${layout_space_display_index}"
  )" || return 0
  layout_display_w="$(jq -r '.frame.w // empty' <<<"${layout_display_json}")"
  layout_display_h="$(jq -r '.frame.h // empty' <<<"${layout_display_json}")"
  [[ -n "${layout_display_w}" && -n "${layout_display_h}" ]] || return 0
  display_profile="$(
    layout_resolve_display_profile "${layout_display_w}" "${layout_display_h}"
  )" || return 0
  layout_area_class="$(jq -r '.area_class' <<<"${display_profile}")"

  preferences="$(
    layout_resolve_preferences "${layout_state_file}" "${layout_area_class}"
  )" || return 0
  layout_mode="$(jq -r '.mode' <<<"${preferences}")"
  layout_last_area_class="$(jq -r '.last_area_class' <<<"${preferences}")"

  [[ -n "${layout_state_file}" ]] || return 0

  if [[
    -n "${layout_last_area_class}" &&
      "${layout_last_area_class}" != "${layout_area_class}"
  ]]; then
    area_change_pending=true
  fi

  [[ "${area_change_pending}" == "true" ]] ||
    [[ "${layout_mode}" != "${requested_mode}" ]] ||
    return 0

  mkdir -p "${LAYOUT_STATE_ROOT}" 2>/dev/null || return 0
  if [[ "${area_change_pending}" == "true" ]]; then
    layout_state_update "${layout_state_file}" \
      selected_layout "${requested_mode}" \
      last_area_class "${layout_area_class}" 2>/dev/null || return 0
  else
    layout_state_update \
      "${layout_state_file}" \
      selected_layout \
      "${requested_mode}" 2>/dev/null || return 0
  fi

  "${LAYOUT_SCRIPT_DIR}/apply-layout.sh" || return 0
  notify_layout_mode "${requested_mode}"
  printf '%s\n' "${requested_mode}"
}

main "$@"
