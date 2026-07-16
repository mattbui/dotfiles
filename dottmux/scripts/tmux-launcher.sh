#!/usr/bin/env bash
set -euo pipefail

directory_icon=""
ssh_icon="󰒋"

report_error() {
  local status="$?"
  local line="${BASH_LINENO[0]:-unknown}"

  trap - ERR
  tmux display-message "tmux launcher failed at line $line (status $status)" 2>/dev/null || true
  exit "$status"
}

trap report_error ERR

list_ssh_hosts() {
  [ -r "${HOME}/.ssh/config" ] || return 0

  awk -v icon="$ssh_icon" '
    tolower($1) == "host" {
      for (i = 2; i <= NF; i++) {
        host = $i
        if (substr(host, 1, 1) == "#") {
          break
        }
        if (index(host, "*") || index(host, "?") || index(host, "!")) {
          continue
        }
        if (!seen[host]++) {
          print icon " " host
        }
      }
    }
  ' "${HOME}/.ssh/config"
}

list_all() {
  sesh list --icons --hide-duplicates --hide-attached
  list_ssh_hosts
}

case "${1:-}" in
  --list-all)
    list_all
    exit 0
    ;;
  --list-ssh-hosts)
    list_ssh_hosts
    exit 0
    ;;
esac

if ! command -v sesh >/dev/null 2>&1; then
  tmux display-message "sesh is not installed"
  exit 1
fi

if ! command -v fzf-tmux >/dev/null 2>&1; then
  tmux display-message "fzf-tmux is not installed"
  exit 1
fi

origin_pane="${TMUX_PANE:-}"
origin_session="$(tmux display-message -p -t "$origin_pane" '#{session_name}')"
origin_path="$(tmux display-message -p -t "$origin_pane" '#{pane_current_path}')"

ssh_command() {
  local host="$1"
  printf 'ssh %q' "$host"
}

ssh_session_name() {
  local host="$1"
  printf 'ssh-%s' "${host//[^[:alnum:]_-]/_}"
}

open_ssh_session() {
  local host="$1"
  local session
  local command

  session="$(ssh_session_name "$host")"
  if tmux has-session -t "=$session" 2>/dev/null; then
    tmux switch-client -t "=$session"
    return 0
  fi

  command="$(ssh_command "$host")"
  tmux new-session -d -s "$session" -c "$origin_path"
  tmux send-keys -t "${session}:" "$command" Enter
  tmux switch-client -t "=$session"
}

open_ssh_window() {
  local host="$1"
  local command
  local pane_id

  command="$(ssh_command "$host")"
  pane_id="$(
    tmux new-window -P -F '#{pane_id}' -t "${origin_session}:" \
      -c "$origin_path" -n "$host"
  )"
  tmux send-keys -t "$pane_id" "$command" Enter
}

result="$({
  list_all |
    fzf-tmux -p 70%,50% \
      --ansi \
      --expect=ctrl-n \
      --height=100% \
      --reverse \
      --border 'sharp' \
      --border-label ' tmux launcher ' \
      --header '↵ new window  ^n new session  ^a all  ^f directories  ^s ssh' \
      --prompt '📺 ' \
      --bind 'ctrl-a:change-prompt(📺 )+reload("$HOME/.config/tmux/scripts/tmux-launcher.sh" --list-all)' \
      --bind 'ctrl-f:change-prompt(🔎 )+reload(fd -H -d 2 -t d -E .Trash . ~ | sed "s/^/ /")' \
      --bind 'ctrl-s:change-prompt(🖥️  )+reload("$HOME/.config/tmux/scripts/tmux-launcher.sh" --list-ssh-hosts)' \
      --preview-window 'right:55%,border-sharp' \
      --preview 'sesh preview {}'
})" || exit 0

[ -n "$result" ] || exit 0

key=""
selection="$result"
if [[ "$result" == *$'\n'* ]]; then
  key="${result%%$'\n'*}"
  selection="${result#*$'\n'}"
fi

[ -n "$selection" ] || exit 0

if [[ "$key" == ctrl-n ]]; then
  if [[ "$selection" == "$ssh_icon "* ]]; then
    open_ssh_session "${selection#"$ssh_icon "}"
    exit 0
  fi
  sesh connect "$selection"
  exit 0
fi

if [[ "$selection" == "$ssh_icon "* ]]; then
  open_ssh_window "${selection#"$ssh_icon "}"
  exit 0
fi

if [[ "$selection" == "$directory_icon "* ]]; then
  sesh window "${selection#"$directory_icon "}"
  exit 0
fi

sesh connect "$selection"
