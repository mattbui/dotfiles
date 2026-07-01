#!/usr/bin/env bash

set -Eeuo pipefail

# Apps to skip when a yabai-initiated space/display switch initially focuses a
# floating/overlay window. Keep this list independent from the yabai manage=off
# ignore list.
focus_skip_apps='Antinote'

state_dir="${YABAI_STATE_DIR:-$HOME/.local/state/yabai}"
token_file="$state_dir/skip-focus.token"
token_ttl_seconds=1

mark_skip_focus() {
  mkdir -p "$state_dir" 2>/dev/null || return 0
  date +%s >"$token_file" 2>/dev/null || true
}

consume_skip_focus_token() {
  local token_time now age

  [[ -f "$token_file" ]] || return 1

  token_time="$(<"$token_file")"
  rm -f "$token_file" 2>/dev/null || true
  [[ "$token_time" =~ ^[0-9]+$ ]] || return 1

  now="$(date +%s)"
  [[ "$now" =~ ^[0-9]+$ ]] || return 1

  age=$((now - token_time))
  ((age >= 0 && age <= token_ttl_seconds))
}

focus_skip_apps_json() {
  local skip

  while IFS= read -r skip; do
    [[ -n "$skip" ]] || continue
    [[ "$skip" == \#* ]] && continue
    printf '%s\n' "$skip"
  done <<<"$focus_skip_apps" | jq -R . | jq -s .
}

is_focus_skip_app() {
  local app="$1"
  local skip

  [[ -n "$app" ]] || return 1

  while IFS= read -r skip; do
    [[ -n "$skip" ]] || continue
    [[ "$skip" == \#* ]] && continue
    [[ "$app" == "$skip" ]] && return 0
  done <<<"$focus_skip_apps"

  return 1
}

current_space() {
  yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty' 2>/dev/null || true
}

focused_app() {
  yabai -m query --windows --window 2>/dev/null | jq -r '.app // empty' 2>/dev/null || true
}

focus_first_non_skip_window_on_current_space() {
  local space skip_apps_json window_id

  space="$(current_space)"
  [[ -n "$space" ]] || return 1

  skip_apps_json="$(focus_skip_apps_json)"
  window_id="$(
    yabai -m query --windows --space "$space" 2>/dev/null |
      jq -er --argjson skip_apps "$skip_apps_json" '
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

  [[ -n "$window_id" && "$window_id" != "null" ]] || return 1
  yabai -m window --focus "$window_id"
}

case "${1:-run}" in
  mark|--mark)
    mark_skip_focus
    exit 0
    ;;
  run|--run)
    ;;
  *)
    echo "Usage: $(basename "$0") [mark|run]" >&2
    exit 2
    ;;
esac

consume_skip_focus_token || exit 0

command -v yabai >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

if is_focus_skip_app "$(focused_app)"; then
  focus_first_non_skip_window_on_current_space || true
fi
