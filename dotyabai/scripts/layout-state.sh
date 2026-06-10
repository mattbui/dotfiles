#!/usr/bin/env sh

# Helpers for per-space dotyabai layout state files.
# State format is simple key=value. Do not source these files.

layout_state_file_for_space() {
  # Use Mission Control space index, matching yabai SPACE_SEL numbers used in
  # rules/keybindings such as `space=1` and `window --space 1`.
  printf '%s/layout-%s' "$state_dir" "$1"
}

layout_state_get() {
  file="$1"
  key="$2"
  default="$3"

  if [ -f "$file" ]; then
    while IFS='=' read -r k v; do
      [ "$k" = "$key" ] || continue
      printf '%s' "$v"
      return 0
    done <"$file"
  fi

  printf '%s' "$default"
}

layout_state_update() {
  file="$1"
  shift

  dir=$(dirname "$file")
  mkdir -p "$dir" 2>/dev/null || return 1
  tmp="$file.$$"
  upd="$file.$$.updates"

  : >"$tmp" || return 1
  : >"$upd" || { rm -f "$tmp"; return 1; }

  while [ "$#" -gt 1 ]; do
    printf '%s=%s\n' "$1" "$2" >>"$upd"
    shift 2
  done

  if [ -f "$file" ]; then
    while IFS='=' read -r k v; do
      [ -n "$k" ] || continue
      if grep -F -q -e "$k=" "$upd" 2>/dev/null; then
        continue
      fi
      printf '%s=%s\n' "$k" "$v" >>"$tmp"
    done <"$file"
  fi

  cat "$upd" >>"$tmp"
  rm -f "$upd"
  mv "$tmp" "$file"
}

valid_ratio() {
  awk "BEGIN { v=\"$1\"+0; exit !(v >= 0.1 && v <= 0.9) }" 2>/dev/null
}

clamp_ratio() {
  awk "BEGIN { v=\"$1\"+0; if (v < 0.1) v=0.1; if (v > 0.9) v=0.9; printf \"%.3f\", v }"
}
