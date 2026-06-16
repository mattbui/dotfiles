#!/usr/bin/env sh

# Manage dotyabai's yabai ignore list.
# Sourceable functions:
#   add_ignore "AppName"
#   remove_ignore "AppName"
#   toggle_ignore "AppName"
#   list_ignore
#   has_ignore "AppName"
#   ignore_rule_label "AppName"
#   ignore_app_regex "AppName"
# CLI:
#   ignore-list.sh add "AppName"
#   ignore-list.sh remove "AppName"
#   ignore-list.sh toggle "AppName"
#   ignore-list.sh list

ignore_state_dir="${YABAI_STATE_DIR:-$HOME/.local/state/yabai}"
ignore_file="$ignore_state_dir/yabaiignore"

ignore_defaults='System Settings
Finder
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
Logi Options+
AppCleaner
Activity Monitor
App Store
Disk Utility
Notes'

ensure_ignore_file() {
  mkdir -p "$ignore_state_dir" 2>/dev/null || return 1

  if [ ! -f "$ignore_file" ]; then
    printf '%s\n' "$ignore_defaults" | sed '/^[[:space:]]*$/d' >"$ignore_file"
  fi
}

normalize_ignore_file() {
  ensure_ignore_file || return 1
  tmp="$ignore_file.$$"
  awk 'NF && !seen[$0]++ { print }' "$ignore_file" >"$tmp" && mv "$tmp" "$ignore_file"
}

list_ignore() {
  ensure_ignore_file || return 1
  sed '/^[[:space:]]*$/d' "$ignore_file"
}

has_ignore() {
  app="$1"
  ensure_ignore_file || return 1
  grep -Fx -- "$app" "$ignore_file" >/dev/null 2>&1
}

add_ignore() {
  app="$1"
  [ -n "$app" ] || return 1
  ensure_ignore_file || return 1

  if has_ignore "$app"; then
    return 0
  fi

  printf '%s\n' "$app" >>"$ignore_file"
  normalize_ignore_file
}

remove_ignore() {
  app="$1"
  [ -n "$app" ] || return 1
  ensure_ignore_file || return 1

  tmp="$ignore_file.$$"
  grep -Fvx -- "$app" "$ignore_file" >"$tmp" || :
  mv "$tmp" "$ignore_file"
}

toggle_ignore() {
  app="$1"
  [ -n "$app" ] || return 1

  if has_ignore "$app"; then
    remove_ignore "$app"
    return 2
  fi

  add_ignore "$app"
  return 0
}

ignore_rule_label() {
  # Keep labels readable, but avoid spaces so CLI remove/apply is predictable.
  printf 'ignore-%s' "$(printf '%s' "$1" | sed 's/[[:space:]]\{1,\}/-/g')"
}

ignore_app_regex() {
  # Escape extended-regex metacharacters, then anchor exact app name.
  printf '^%s$' "$(printf '%s' "$1" | sed 's/[.[\*^$()+?{}|\\]/\\&/g')"
}

apply_ignore_rule_live() {
  app="$1"
  command -v yabai >/dev/null 2>&1 || return 0

  label=$(ignore_rule_label "$app")
  regex=$(ignore_app_regex "$app")

  yabai -m rule --remove "$label" >/dev/null 2>&1 || :
  yabai -m rule --add label="$label" app="$regex" manage=off >/dev/null 2>&1 || return 0
  yabai -m rule --apply "$label" >/dev/null 2>&1 || :
}

remove_ignore_rule_live() {
  app="$1"
  command -v yabai >/dev/null 2>&1 || return 0

  label=$(ignore_rule_label "$app")
  yabai -m rule --remove "$label" >/dev/null 2>&1 || :
}

notify_ignore() {
  subtitle="$1"
  message="$2"
  command -v osascript >/dev/null 2>&1 || return 0

  osascript <<EOF >/dev/null 2>&1
display notification "$(printf '%s' "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')" with title "yabai" subtitle "$(printf '%s' "$subtitle" | sed 's/\\/\\\\/g; s/"/\\"/g')"
EOF
}

run_apply_layout() {
  script_dir=$(dirname "$0")
  if [ -x "$script_dir/apply-layout.sh" ]; then
    "$script_dir/apply-layout.sh" >/dev/null 2>&1 &
  elif [ -x "$HOME/.config/yabai/scripts/apply-layout.sh" ]; then
    "$HOME/.config/yabai/scripts/apply-layout.sh" >/dev/null 2>&1 &
  fi
}

# If sourced, only define functions.
if [ "${0##*/}" != "ignore-list.sh" ]; then
  return 0 2>/dev/null || exit 0
fi

usage() {
  printf '%s\n' \
    'usage: ignore-list.sh add "AppName"' \
    '       ignore-list.sh remove "AppName"' \
    '       ignore-list.sh toggle "AppName"' \
    '       ignore-list.sh list'
}

cmd="${1:-}"
case "$cmd" in
  add)
    app="$2"
    [ -n "$app" ] || { usage >&2; exit 1; }
    if has_ignore "$app"; then
      notify_ignore "Ignore unchanged" "$app already ignored"
    else
      add_ignore "$app"
      apply_ignore_rule_live "$app"
      notify_ignore "Ignore added" "$app"
    fi
    ;;
  remove)
    app="$2"
    [ -n "$app" ] || { usage >&2; exit 1; }
    if has_ignore "$app"; then
      remove_ignore "$app"
      remove_ignore_rule_live "$app"
      notify_ignore "Ignore removed" "$app"
    else
      notify_ignore "Ignore unchanged" "$app was not ignored"
    fi
    ;;
  toggle)
    app="$2"
    [ -n "$app" ] || { usage >&2; exit 1; }
    if has_ignore "$app"; then
      remove_ignore "$app"
      remove_ignore_rule_live "$app"
      notify_ignore "Ignore removed" "$app"
    else
      add_ignore "$app"
      apply_ignore_rule_live "$app"
      notify_ignore "Ignore added" "$app"
    fi
    run_apply_layout
    ;;
  list)
    list_ignore
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
