#!/bin/sh

# Open revdiff in a tmux popup centered in the tmux window.
#
# Usage:
#   revdiff-popup.sh --visual -- [revdiff args...]
#   revdiff-popup.sh --output /tmp/annotations.md -- [revdiff args...]
#   revdiff-popup.sh --clipboard -- [revdiff args...]

set -eu

usage() {
  echo "usage: $0 (--visual | --output FILE | --clipboard) -- [revdiff args...]" >&2
}

notify() {
  if [ -n "${TMUX:-}" ]; then
    tmux display-message "$*"
  else
    printf '%s\n' "$*" >&2
  fi
}

copy_to_clipboard() {
  file=$1

  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$file"
    return
  fi

  if command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$file"
    return
  fi

  if command -v xclip >/dev/null 2>&1; then
    xclip -in -selection clipboard < "$file"
    return
  fi

  if command -v xsel >/dev/null 2>&1; then
    xsel --clipboard --input < "$file"
    return
  fi

  return 1
}

cleanup_clipboard_temp() {
  rm -rf "$temp_dir"
}

run_revdiff() {
  mode=${1:-}
  shift || true

  output_file=
  copy_output=0
  case "$mode" in
    --visual)
      ;;
    --output)
      if [ $# -eq 0 ]; then
        usage
        exit 2
      fi
      output_file=$1
      shift
      ;;
    --clipboard)
      copy_output=1
      ;;
    *)
      usage
      exit 2
      ;;
  esac

  if [ "${1:-}" = "--" ]; then
    shift
  fi

  if [ "$copy_output" -eq 1 ]; then
    temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/revdiff-clipboard.XXXXXX")
    trap cleanup_clipboard_temp EXIT HUP INT TERM
    output_file="$temp_dir/annotations.md"

    set +e
    "${REVDIFF_BIN:-revdiff}" --output "$output_file" "$@"
    status=$?
    set -e

    if [ -s "$output_file" ]; then
      if copy_to_clipboard "$output_file"; then
        notify "Copied revdiff annotations to clipboard"
        exit 0
      fi

      notify "No clipboard command found for revdiff annotations"
      exit 1
    fi

    if [ "$status" -eq 0 ] || [ "$status" -eq 10 ]; then
      notify "No revdiff annotations captured"
      exit 0
    fi

    notify "revdiff exited with code $status"
    exit "$status"
  fi

  if [ -n "$output_file" ]; then
    exec "${REVDIFF_BIN:-revdiff}" --output "$output_file" "$@"
  fi

  exec "${REVDIFF_BIN:-revdiff}" "$@"
}

if [ "${1:-}" = "__run" ]; then
  shift
  run_revdiff "$@"
fi

case "${1:-}" in
  --visual)
    ;;
  --output)
    if [ $# -lt 2 ]; then
      usage
      exit 2
    fi
    ;;
  --clipboard)
    ;;
  *)
    usage
    exit 2
    ;;
esac

if [ -z "${TMUX:-}" ]; then
  echo "revdiff popup requires tmux" >&2
  exit 1
fi

case "$0" in
  /*) self=$0 ;;
  *) self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0") ;;
esac

# Prefer tmux's current command context over the inherited TMUX_PANE value.
# TMUX_PANE can be stale for tmux run-shell/background invocations, which makes
# the popup size/position get calculated from the wrong pane.
tmux_pane=$(tmux display-message -p '#{pane_id}' 2>/dev/null || true)
if [ -z "$tmux_pane" ]; then
  tmux_pane=${TMUX_PANE:-}
fi

if [ -z "$tmux_pane" ]; then
  echo "revdiff popup requires an active tmux pane" >&2
  exit 1
fi

pane_path=$(tmux display-message -p -t "$tmux_pane" '#{pane_current_path}' 2>/dev/null || printf '%s' "${PWD:-$HOME}")

exec tmux display-popup \
  -E \
  -t "$tmux_pane" \
  -w 90% \
  -h 70% \
  -d "$pane_path" \
  "$self" __run "$@"
