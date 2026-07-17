#!/usr/bin/env bash
set -euo pipefail

directory_icon=""
ssh_icon=""
launcher_path="${BASH_SOURCE[0]}"

if [[ "$launcher_path" != /* ]]; then
  launcher_path="${PWD}/${launcher_path}"
fi

report_error() {
  local status="$?"
  local line="${BASH_LINENO[0]:-unknown}"

  trap - ERR
  tmux display-message "tmux launcher failed at line $line (status $status)" 2>/dev/null || true
  exit "$status"
}

trap report_error ERR

# Mirror aliases.zsh's ssh() behavior for launcher panes by setting the tmux
# pane title metadata, using a block cursor during SSH, then restoring to beam cursor.
run_ssh_pane() {
  local host="$1"
  local shell="${SHELL:-/bin/zsh}"

  if [[ -n "${TMUX_PANE:-}" ]]; then
    tmux set-option -p -t "$TMUX_PANE" @ssh_session_active 1
    tmux set-option -p -t "$TMUX_PANE" @ssh_session_name "$host"
  fi

  printf '\e[2 q'
  printf 'Connecting to %s...\n' "$host"
  if command ssh "$host"; then
    :
  fi
  printf '\e[6 q'

  if [[ -n "${TMUX_PANE:-}" ]]; then
    tmux set-option -p -u -t "$TMUX_PANE" @ssh_session_active 2>/dev/null || true
    tmux set-option -p -u -t "$TMUX_PANE" @ssh_session_name 2>/dev/null || true
  fi

  exec "$shell" -l
}

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

list_directories() {
  local root
  local roots=("${HOME}")

  for root in \
    "${HOME}/glimpse" \
    "${HOME}/Documents" \
    "${HOME}/Pictures" \
    "${HOME}/Downloads" \
    "${HOME}/.config"; do
    [ -d "$root" ] && roots+=("$root")
  done

  fd --hidden --max-depth 1 --type directory \
    . "${roots[@]}" | sed -e 's:/$::' -e "s/^/$directory_icon /"
}

list_all() {
  sesh list --icons --hide-duplicates --hide-attached
  list_ssh_hosts
}

case "${1:-}" in
  --ssh-pane)
    [[ "$#" -eq 2 ]] || exit 2
    run_ssh_pane "$2"
    ;;
  --list-all)
    list_all
    exit 0
    ;;
  --list-directories)
    list_directories
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

ssh_pane_command() {
  local host="$1"
  printf '%q --ssh-pane %q' "$launcher_path" "$host"
}

ssh_session_name() {
  local host="$1"
  printf '@%s' "${host//[^[:alnum:]_-]/_}"
}

open_ssh_session() {
  local host="$1"
  local session
  local pane_command

  session="$(ssh_session_name "$host")"
  pane_command="$(ssh_pane_command "$host")"

  if tmux has-session -t "=$session" 2>/dev/null; then
    tmux set-option -t "=$session:" default-command "$pane_command"
    tmux switch-client -t "=$session"
    return 0
  fi

  tmux new-session -d -s "$session" -c "$origin_path" "$pane_command"
  tmux set-option -t "=$session:" default-command "$pane_command"
  tmux switch-client -t "=$session"
}

open_ssh_window() {
  local host="$1"
  local pane_command

  pane_command="$(ssh_pane_command "$host")"
  tmux new-window -t "${origin_session}:" -c "$origin_path" -n "$host" \
    "$pane_command"
}

result="$({
  list_all |
    fzf-tmux -p 80%,60% \
      --ansi \
      --expect=ctrl-n \
      --height=100% \
      --border 'sharp' \
      --border-label-pos=2 \
      --border-label ' tmux launcher · ↵ : new window · ^n: new session · ^a: all · ^f: dirs · ^s: ssh ' \
      --prompt '📺 ' \
      --bind 'ctrl-a:change-prompt(📺 )+reload("$HOME/.config/tmux/scripts/tmux-launcher.sh" --list-all)' \
      --bind 'ctrl-f:change-prompt(🔎 )+reload("$HOME/.config/tmux/scripts/tmux-launcher.sh" --list-directories)' \
      --bind 'ctrl-s:change-prompt(🖥️  )+reload("$HOME/.config/tmux/scripts/tmux-launcher.sh" --list-ssh-hosts)' \
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
