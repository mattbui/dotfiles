#!/usr/bin/env bash

set -Eeuo pipefail

notify_error() {
  local message="$1"
  command -v osascript >/dev/null 2>&1 || return 0

  osascript <<EOF >/dev/null 2>&1
display notification "$(printf '%s' "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')" with title "yabai" subtitle "Focus App Error"
EOF
}

on_error() {
  local status=$?
  notify_error "Failed to focus/open ${app_name:-unknown app} (exit $status)"
}

trap on_error ERR

usage() {
  echo "Usage: $(basename "$0") <application-name>" >&2
  echo "Example: $(basename "$0") Safari" >&2
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

app_name="$*"

state_dir="$HOME/.local/state/yabai"
mkdir -p "$state_dir" 2>/dev/null
latest_focus_file="$state_dir/focus-app.latest"
focus_request="$$-$(date +%s%N)-$app_name"
printf '%s\n' "$focus_request" >"$latest_focus_file"

# Focus requests can overlap when hotkeys are pressed faster than macOS/yabai
# finishes a cross-space focus. Make the newest request win: older invocations
# check this latest-request marker between async-ish yabai operations and exit
# before they can steal focus back.
is_latest_focus_request() {
  [[ -f "$latest_focus_file" ]] && [[ "$(<"$latest_focus_file")" == "$focus_request" ]]
}

if ! command -v yabai >/dev/null 2>&1; then
  echo "Error: yabai is not available in PATH" >&2
  exit 127
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is not available in PATH" >&2
  exit 127
fi

# Pick the first matching window from yabai's default query order.
# In practice this tends to correlate with WindowServer z-order / recent focus.
#
# We intentionally exclude minimized windows, but allow hidden or not currently
# visible windows; focusing their space first can make them focusable.
window_json="$(
  yabai -m query --windows |
    jq -cer --arg app "$app_name" '
      [
        .[]
        | select(.app == $app)
        | select(."is-minimized" == false)
      ][0] // empty
    ' 2>/dev/null || true
)"

if [[ -z "$window_json" ]]; then
  is_latest_focus_request || exit 0
  if ! open_error=$(open -a "$app_name" 2>&1); then
    printf '%s\n' "$open_error" >&2
    notify_error "$open_error"
    exit 1
  fi
  exit 0
fi

window_id="$(jq -r '.id' <<<"$window_json")"
window_space="$(jq -r '.space' <<<"$window_json")"
# Window `.space` is the Mission Control index, not the stable space id.
current_space="$(yabai -m query --spaces --space | jq -r '.index')"

# Focus the space first to avoid the cross-space window-focus sliding animation.
if [[ -n "$window_space" && "$window_space" != "null" && "$window_space" != "$current_space" ]]; then
  is_latest_focus_request || exit 0
  yabai -m space --focus "$window_space"

  for _ in {1..10}; do
    is_latest_focus_request || exit 0
    [[ "$(yabai -m query --spaces --space | jq -r '.index')" == "$window_space" ]] && break
    sleep 0.05
  done
fi

# After switching spaces, macOS may initially focus that space's previous window.
# Retry until the requested window actually has focus.
for _ in {1..10}; do
  is_latest_focus_request || exit 0
  yabai -m window --focus "$window_id" || true
  yabai -m query --windows --window "$window_id" | jq -e '."has-focus" == true' >/dev/null && exit 0
  sleep 0.05
done

notify_error "Timed out focusing $app_name"
exit 1
