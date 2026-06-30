#!/usr/bin/env sh

notify() {
  command -v osascript >/dev/null 2>&1 || return 0
  osascript -e "display notification \"$1\" with title \"yabai\"" >/dev/null 2>&1
}

is_ready() {
  yabai -m query --spaces >/dev/null 2>&1
}

old_pids="$(pgrep -x yabai 2>/dev/null | tr '\n' ' ')"

notify "Restarting yabai..."

if ! yabai --restart-service; then
  status=$?
  notify "Restart failed"
  exit "$status"
fi

attempts=40
while [ "$attempts" -gt 0 ]; do
  current_pids="$(pgrep -x yabai 2>/dev/null | tr '\n' ' ')"

  if [ -n "$current_pids" ] && [ "$current_pids" != "$old_pids" ] && is_ready; then
    notify "Restart complete"
    exit 0
  fi

  attempts=$((attempts - 1))
  sleep 0.25
done

notify "Restart timed out"
exit 1
