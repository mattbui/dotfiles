#!/usr/bin/env bash

notify() {
  local message="$1"

  command -v osascript >/dev/null 2>&1 || return 0
  osascript \
    -e "display notification \"${message}\" with title \"yabai\"" \
    >/dev/null 2>&1
}

yabai_is_ready() {
  yabai -m query --spaces >/dev/null 2>&1
}

main() {
  local old_pids
  local status
  local attempts_remaining=40
  local current_pids

  old_pids="$(pgrep -x yabai 2>/dev/null | tr '\n' ' ')"
  notify "Restarting yabai..."

  if yabai --restart-service; then
    :
  else
    status=$?
    notify "Restart failed"
    return "${status}"
  fi

  while (( attempts_remaining > 0 )); do
    current_pids="$(pgrep -x yabai 2>/dev/null | tr '\n' ' ')"

    if [[
      -n "${current_pids}" &&
        "${current_pids}" != "${old_pids}"
    ]] && yabai_is_ready; then
      notify "Restart complete"
      return 0
    fi

    ((attempts_remaining -= 1))
    sleep 0.25
  done

  notify "Restart timed out"
  return 1
}

main "$@"
