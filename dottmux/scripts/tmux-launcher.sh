#!/usr/bin/env bash
set -euo pipefail

directory_icon=""
ssh_icon=""
launcher_path="${BASH_SOURCE[0]}"
inside_tmux=false
new_session_mode=false
change_directory_mode=false
store_directory_selection=false

if [[ "$launcher_path" != /* ]]; then
  launcher_path="${PWD}/${launcher_path}"
fi

if [[ -n "${TMUX:-}" ]]; then
  inside_tmux=true
fi

tmux_command() {
  if $inside_tmux || [[ -z "${TMUX_SOCKET:-}" ]]; then
    command tmux "$@"
  else
    command tmux -L "$TMUX_SOCKET" "$@"
  fi
}

report_error() {
  local status="$?"
  local line="${BASH_LINENO[0]:-unknown}"

  trap - ERR
  if $inside_tmux; then
    tmux_command display-message \
      "tmux launcher failed at line $line (status $status)" 2>/dev/null || true
  else
    printf 'tmux launcher failed at line %s (status %s)\n' "$line" "$status" >&2
  fi
  exit "$status"
}

trap report_error ERR

# Mirror aliases.zsh's ssh() behavior for launcher panes by setting the tmux
# pane title metadata, using a block cursor during SSH, then restoring to beam cursor.
run_ssh_pane() {
  local host="$1"
  local shell="${SHELL:-/bin/zsh}"

  if [[ -n "${TMUX_PANE:-}" ]]; then
    tmux_command set-option -p -t "$TMUX_PANE" @ssh_session_active 1
    tmux_command set-option -p -t "$TMUX_PANE" @ssh_session_name "$host"
  fi

  printf '\e[2 q'
  printf 'Connecting to %s...\n' "$host"
  if command ssh "$host"; then
    :
  fi
  printf '\e[6 q'

  if [[ -n "${TMUX_PANE:-}" ]]; then
    tmux_command set-option -p -u -t "$TMUX_PANE" @ssh_session_active 2>/dev/null || true
    tmux_command set-option -p -u -t "$TMUX_PANE" @ssh_session_name 2>/dev/null || true
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

list_new_session_targets() {
  sesh list --icons --zoxide
  list_ssh_hosts
}

list_recent_directories() {
  sesh list --icons --zoxide
}

preview_selection() {
  local selection="$1"
  local host
  local session_name="${selection#* }"

  if [[ "$selection" == "$ssh_icon "* ]]; then
    host="${selection#"$ssh_icon "}"
    ssh -G "$host" 2>/dev/null |
      awk '
        /^hostname /     { hostname = $0 }
        /^port /         { port = $0 }
        /^user /         { user = $0 }
        /^proxyjump /    { proxyjump = $0 }
        /^identityfile / { identityfiles = identityfiles $0 ORS }
        END {
          if (hostname != "") print hostname
          if (port != "") print port
          if (user != "") print user
          if (proxyjump != "") print proxyjump
          printf "%s", identityfiles
        }
      '
    return
  fi

  # A leading @ is parsed as a tmux session ID unless exact-name matching is used.
  if [[ "$session_name" == @* ]] &&
    tmux_command has-session -t "=$session_name" 2>/dev/null; then
    tmux_command capture-pane -e -p -t "=$session_name:"
    return
  fi

  sesh preview "$selection"
}

case "${1:-}" in
  --new-session)
    [[ "$#" -eq 1 ]] || exit 2
    new_session_mode=true
    ;;
  --change-directory)
    [[ "$#" -eq 1 ]] || exit 2
    change_directory_mode=true
    ;;
  --select-directory)
    [[ "$#" -eq 1 ]] || exit 2
    change_directory_mode=true
    store_directory_selection=true
    ;;
  --ssh-pane)
    [[ "$#" -eq 2 ]] || exit 2
    run_ssh_pane "$2"
    ;;
  --list-all)
    list_all
    exit 0
    ;;
  --list-new-session-targets)
    list_new_session_targets
    exit 0
    ;;
  --list-recent-directories)
    list_recent_directories
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
  --preview)
    [[ "$#" -eq 2 ]] || exit 2
    preview_selection "$2"
    exit 0
    ;;
esac

if $change_directory_mode && ! $inside_tmux; then
  printf 'tmux launcher: changing the session path requires an active tmux session\n' >&2
  exit 1
fi

if ! command -v sesh >/dev/null 2>&1; then
  if $inside_tmux; then
    tmux_command display-message "sesh is not installed"
  else
    printf 'tmux launcher: sesh is not installed\n' >&2
  fi
  exit 1
fi

picker=(fzf)
if $inside_tmux; then
  picker=(fzf-tmux -p '80%,70%')
fi

if ! command -v "${picker[0]}" >/dev/null 2>&1; then
  if $inside_tmux; then
    tmux_command display-message "${picker[0]} is not installed"
  else
    printf 'tmux launcher: %s is not installed\n' "${picker[0]}" >&2
  fi
  exit 1
fi

origin_session=""
origin_session_id=""
origin_path="$PWD"
if $inside_tmux; then
  origin_pane="${TMUX_PANE:-}"
  origin_session="$(tmux_command display-message -p -t "$origin_pane" '#{session_name}')"
  origin_session_id="$(tmux_command display-message -p -t "$origin_pane" '#{session_id}')"
  origin_path="$(tmux_command display-message -p -t "$origin_pane" '#{pane_current_path}')"
fi

expand_path() {
  local path="$1"

  case "$path" in
    "~")
      printf '%s\n' "$HOME"
      ;;
    "~"/*)
      printf '%s/%s\n' "$HOME" "${path:2}"
      ;;
    *)
      printf '%s\n' "$path"
      ;;
  esac
}

session_name_from_path() {
  local path="$1"
  local git_root=""
  local name
  local relative_path

  git_root="$(git -C "$path" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$git_root" && ( "$path" == "$git_root" || "$path" == "$git_root/"* ) ]]; then
    name="${git_root##*/}"
    relative_path="${path#"$git_root"}"
    name+="$relative_path"
  else
    name="${path%/}"
    name="${name##*/}"
  fi

  name="${name//./_}"
  name="${name//:/_}"
  name="$(printf '%s\n' "$name" | awk '{$1=$1; gsub(/[[:space:]]+/, "_"); print}')"
  printf '%s\n' "$name"
}

unique_session_name() {
  local base_name="$1"
  local candidate="$base_name"
  local number=2

  while tmux_command has-session -t "=$candidate" 2>/dev/null; do
    candidate="$base_name($number)"
    ((number += 1))
  done

  printf '%s\n' "$candidate"
}

switch_or_attach_session() {
  local session="$1"

  if $inside_tmux; then
    tmux_command switch-client -t "=$session"
  else
    tmux_command attach-session -t "=$session"
  fi
}

create_new_session() {
  local base_name="$1"
  local path="$2"
  local session

  [[ "$base_name" == *[![:space:]]* && -d "$path" ]] || return 1
  session="$(unique_session_name "$base_name")"
  tmux_command new-session -d -s "$session" -c "$path"
  switch_or_attach_session "$session"
}

ssh_pane_command() {
  local host="$1"
  printf '%q --ssh-pane %q' "$launcher_path" "$host"
}

ssh_session_name() {
  local host="$1"
  printf '@%s' "${host//[^[:alnum:]_-]/_}"
}

connect_session() {
  local selection="$1"
  local session_name="${selection#* }"

  # A leading @ is parsed as a tmux session ID unless exact-name matching is used.
  if [[ "$session_name" == @* ]] &&
    tmux_command has-session -t "=$session_name" 2>/dev/null; then
    switch_or_attach_session "$session_name"
    return
  fi

  sesh connect "$selection"
}

create_new_ssh_session() {
  local host="$1"
  local session
  local pane_command

  session="$(unique_session_name "$(ssh_session_name "$host")")"
  pane_command="$(ssh_pane_command "$host")"
  tmux_command new-session -d -s "$session" -c "$origin_path" "$pane_command"
  tmux_command set-option -t "=$session:" default-command "$pane_command"
  switch_or_attach_session "$session"
}

input_label=' Tmux launcher '
list_label=' ↵ : connect · ⌘ ↵ : new session · ^r: recent · ^g: root dirs · ^s: ssh '
prompt='📺 '
initial_source=list_all
source_option=--list-all
show_ssh_source=true

if $change_directory_mode; then
  input_label=' Change session path '
  list_label=' ↵ : set session path · ^r: recent dirs · ^g: root dirs '
  prompt='📍 '
  initial_source=list_recent_directories
  source_option=--list-recent-directories
  show_ssh_source=false
elif $new_session_mode; then
  input_label=' New tmux session '
  list_label=' ↵ : new session · ⌘ ↵ : create by name · ^r: recent · ^g: root dirs · ^s: ssh '
  prompt='🌱 '
  initial_source=list_new_session_targets
  source_option=--list-new-session-targets
elif $inside_tmux; then
  list_label=' ↵ : new window · ⌘ ↵ : new session · ^r: recent · ^g: root dirs · ^s: ssh '
fi

launcher_command="\"\$HOME/.config/tmux/scripts/tmux-launcher.sh\""
source_bindings=(
  --bind "ctrl-r:change-prompt($prompt)+reload($launcher_command $source_option)"
  --bind "ctrl-g:change-prompt(📁 )+reload($launcher_command --list-directories)"
)
if $show_ssh_source; then
  source_bindings+=(
    --bind "ctrl-s:change-prompt(🖥️  )+reload($launcher_command --list-ssh-hosts)"
  )
fi

result="$({
  "$initial_source" |
    "${picker[@]}" \
      --ansi \
      --expect=alt-enter \
      --print-query \
      --height=100% \
      --border=none \
      --input-label "$input_label" \
      --list-label "$list_label" \
      --prompt "$prompt" \
      "${source_bindings[@]}" \
      --preview "$launcher_command --preview {}"
})" || exit 0

[ -n "$result" ] || exit 0

query="${result%%$'\n'*}"
result="${result#*$'\n'}"
key="${result%%$'\n'*}"
selection="${result#*$'\n'}"

if $change_directory_mode; then
  [[ -n "$selection" && "$selection" == "$directory_icon "* ]] || exit 0
  target_path="$(expand_path "${selection#"$directory_icon "}")"
  target_path="$(cd "$target_path" && pwd -P)"
  if $store_directory_selection; then
    tmux_command set-option -p -t "$origin_pane" @session_path_selection "$target_path"
  else
    tmux_command attach-session -E -c "$target_path" -t "$origin_session_id"
    tmux_command display-message "Session path: $target_path"
  fi
  exit 0
fi

if $new_session_mode; then
  if [[ "$key" == alt-enter ]]; then
    [[ "$query" == *[![:space:]]* ]] || exit 0
    create_new_session "$query" "$origin_path"
    exit 0
  fi

  [ -n "$selection" ] || exit 0
  if [[ "$selection" == "$ssh_icon "* ]]; then
    create_new_ssh_session "${selection#"$ssh_icon "}"
    exit 0
  fi

  if [[ "$selection" == "$directory_icon "* ]]; then
    target_path="$(expand_path "${selection#"$directory_icon "}")"
    target_path="$(cd "$target_path" && pwd -P)"
    create_new_session "$(session_name_from_path "$target_path")" "$target_path"
  fi
  exit 0
fi

[ -n "$selection" ] || exit 0

if [[ "$key" == alt-enter ]]; then
  if [[ "$selection" == "$ssh_icon "* ]]; then
    create_new_ssh_session "${selection#"$ssh_icon "}"
    exit 0
  fi

  session_name="${selection#* }"
  if tmux_command has-session -t "=$session_name" 2>/dev/null; then
    connect_session "$selection"
    exit 0
  fi

  if [[ "$selection" == "$directory_icon "* ]]; then
    target_path="$(expand_path "${selection#"$directory_icon "}")"
    target_path="$(cd "$target_path" && pwd -P)"
    create_new_session "$(session_name_from_path "$target_path")" "$target_path"
    exit 0
  fi

  connect_session "$selection"
  exit 0
fi

if [[ "$selection" == "$ssh_icon "* ]]; then
  if $inside_tmux; then
    host="${selection#"$ssh_icon "}"
    pane_command="$(ssh_pane_command "$host")"
    tmux_command new-window -t "${origin_session}:" -c "$origin_path" -n "$host" \
      "$pane_command"
  else
    create_new_ssh_session "${selection#"$ssh_icon "}"
  fi
  exit 0
fi

if [[ "$selection" == "$directory_icon "* ]]; then
  if $inside_tmux; then
    sesh window "${selection#"$directory_icon "}"
  else
    connect_session "$selection"
  fi
  exit 0
fi

connect_session "$selection"
