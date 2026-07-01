#!/usr/bin/env bash

# Restore focus after close/Cmd-W by focusing a visible window on the current space.

set -u
set -o pipefail

event_name="${1:-unknown}"

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# skhd passthrough can start before the app handles Cmd-W.
case "$event_name" in
  hotkey_cmd_w) sleep 0.15 ;;
esac

macos_front_app() {
  command -v osascript >/dev/null 2>&1 || return 0

  osascript <<'EOF' 2>/dev/null || true
tell application "System Events"
  set frontApps to name of application processes whose frontmost is true
  if (count of frontApps) > 0 then return item 1 of frontApps
end tell
EOF
}

current_space() {
  yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty' 2>/dev/null || true
}

focused_window_json() {
  yabai -m query --windows --window 2>/dev/null || printf 'null\n'
}

is_usable_window_json() {
  jq -e '
    . != null
    and ."is-visible" == true
    and ."is-minimized" == false
    and ."is-hidden" == false
    and ."has-ax-reference" == true
  ' >/dev/null 2>&1 <<<"$1"
}

front_app_usable_window_id() {
  local front_app="$1" space="$2"
  [[ -n "$front_app" && -n "$space" ]] || return 1

  yabai -m query --windows --space "$space" 2>/dev/null |
    jq -er --arg app_lc "$(printf '%s' "$front_app" | tr '[:upper:]' '[:lower:]')" '
      [
        .[]
        | select((.app | ascii_downcase) == $app_lc)
        | select(."is-visible" == true)
        | select(."is-minimized" == false)
        | select(."is-hidden" == false)
        | select(."has-ax-reference" == true)
      ] as $windows
      | ((($windows | map(select(."is-floating" == false))) + ($windows | map(select(."is-floating" == true))))[0].id // empty)
    ' 2>/dev/null || true
}

fallback_window_id() {
  local space="$1" front_app="$2"
  [[ -n "$space" ]] || return 1

  yabai -m query --windows --space "$space" 2>/dev/null |
    jq -er --arg app_lc "$(printf '%s' "$front_app" | tr '[:upper:]' '[:lower:]')" '
      [
        .[]
        | select(."is-visible" == true)
        | select(."is-minimized" == false)
        | select(."is-hidden" == false)
        | select(."has-ax-reference" == true)
        | select((.app | ascii_downcase) != $app_lc)
      ] as $windows
      | ((($windows | map(select(."is-floating" == false))) + ($windows | map(select(."is-floating" == true))))[0].id // empty)
    ' 2>/dev/null || true
}

try_refocus_once() {
  local front_app space focused_json front_window_id candidate_id

  front_app="$(macos_front_app)"
  space="$(current_space)"
  [[ -n "$space" ]] || return 1

  focused_json="$(focused_window_json)"
  if is_usable_window_json "$focused_json"; then
    return 0
  fi

  # If the front app still has another real visible window, keep focus there.
  front_window_id="$(front_app_usable_window_id "$front_app" "$space")"
  if [[ -n "$front_window_id" && "$front_window_id" != "null" ]]; then
    yabai -m window --focus "$front_window_id" >/dev/null 2>&1 || return 1
    return 0
  fi

  candidate_id="$(fallback_window_id "$space" "$front_app")"
  [[ -n "$candidate_id" && "$candidate_id" != "null" ]] || return 1

  yabai -m window --focus "$candidate_id" >/dev/null 2>&1
}

for delay in 0.05 0.10 0.20 0.40; do
  sleep "$delay"
  try_refocus_once && exit 0
done

exit 0
