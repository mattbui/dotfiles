#!/usr/bin/env sh

# Helpers for per-space dotyabai JSON layout state files.
# Do not source state files.

layout_state_file_for_space_label() {
  # Use the yabai space label for per-space layout state.
  # Example: space-1 -> layout-space-1.json
  printf '%s/layout-%s.json' "$state_dir" "$1"
}

layout_state_get() {
  local file key default
  file="$1"
  key="$2"
  default="$3"

  if [ -f "$file" ] && jq -e . "$file" >/dev/null 2>&1; then
    jq -r --arg key "$key" --arg default "$default" 'if has($key) and .[$key] != null then .[$key] else $default end' "$file" 2>/dev/null
    return 0
  fi

  printf '%s' "$default"
}

layout_state_json_set() {
  local src dst key value
  src="$1"
  dst="$2"
  key="$3"
  value="$4"

  jq --arg key "$key" --arg value "$value" '.[$key] = ($value | tonumber? // $value)' "$src" >"$dst"
}

layout_state_update() {
  local file dir tmp next
  file="$1"
  shift

  dir=$(dirname "$file")
  mkdir -p "$dir" 2>/dev/null || return 1
  tmp="$file.$$"
  next="$file.$$.next"

  if [ -f "$file" ] && jq -e . "$file" >/dev/null 2>&1; then
    cp "$file" "$tmp" || return 1
  else
    printf '{}\n' >"$tmp" || return 1
  fi

  while [ "$#" -gt 1 ]; do
    if layout_state_json_set "$tmp" "$next" "$1" "$2"; then
      mv "$next" "$tmp"
    else
      rm -f "$tmp" "$next"
      return 1
    fi
    shift 2
  done

  if [ -f "$file" ] && cmp -s "$tmp" "$file"; then
    rm -f "$tmp"
    return 0
  fi

  mv "$tmp" "$file"
}

valid_ratio() {
  awk "BEGIN { v=\"$1\"+0; exit !(v >= 0.1 && v <= 0.9) }" 2>/dev/null
}

clamp_ratio() {
  awk "BEGIN { v=\"$1\"+0; if (v < 0.1) v=0.1; if (v > 0.9) v=0.9; printf \"%.3f\", v }"
}
