#!/bin/sh
popup_script=/Users/minhbui/dotfiles/dotcodex/hooks/codex_tmux_title_popup.sh

[ "${CODEX_TMUX_TITLE_HOOK:-}" = 1 ] || exit 0
[ -n "${TMUX:-}" ] || exit 0

shell_quote() {
  printf "'"
  printf '%s' "$1" | sed "s/'/'\\\\''/g"
  printf "'"
}

cat >/dev/null

tmux_pane=${TMUX_PANE:-}
if [ -z "$tmux_pane" ]; then
  tmux_pane=$(tmux display-message -p '#{pane_id}' 2>/dev/null || true)
fi

[ -n "$tmux_pane" ] || exit 0

tmux set-option -p -t "$tmux_pane" @codex_session_active 1 2>/dev/null || true
tmux set-option -p -u -t "$tmux_pane" @codex_session_name 2>/dev/null || true

popup_command="$popup_script $(shell_quote "$tmux_pane")"
pane_left=$(tmux display-message -p -t "$tmux_pane" '#{pane_left}' 2>/dev/null || printf 0)
pane_top=$(tmux display-message -p -t "$tmux_pane" '#{pane_top}' 2>/dev/null || printf 0)
pane_width=$(tmux display-message -p -t "$tmux_pane" '#{pane_width}' 2>/dev/null || printf 60)
pane_height=$(tmux display-message -p -t "$tmux_pane" '#{pane_height}' 2>/dev/null || printf 7)

popup_width=60
popup_height=7

[ "$pane_width" -lt "$popup_width" ] && popup_width=$pane_width
[ "$pane_height" -lt "$popup_height" ] && popup_height=$pane_height

popup_x=$((pane_left + (pane_width - popup_width) / 2))
popup_y=$((pane_top + (pane_height - popup_height) / 2))

tmux display-popup \
  -E \
  -t "$tmux_pane" \
  -T 'Tmux pane title' \
  -x "$popup_x" \
  -y "$popup_y" \
  -w "$popup_width" \
  -h "$popup_height" \
  "$popup_command" \
  >/dev/null 2>&1 &
