#!/bin/sh

# Open revdiff in a tmux popup centered in the tmux window.
#
# Usage:
#   revdiff-popup.sh --visual -- [revdiff args...]
#   revdiff-popup.sh --output /tmp/annotations.md -- [revdiff args...]

set -eu

usage() {
  echo "usage: $0 (--visual | --output FILE) -- [revdiff args...]" >&2
}

run_revdiff() {
  mode=${1:-}
  shift || true

  output_file=
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
    *)
      usage
      exit 2
      ;;
  esac

  if [ "${1:-}" = "--" ]; then
    shift
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
