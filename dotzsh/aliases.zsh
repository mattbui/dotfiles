# My aliases

alias e=$EDITOR
alias v=$VISUAL
alias cd='z'
alias 'cd!'='builtin cd'

alias fa='alias | fzf'  # fuzzy find alias
tmux() {
    # Use native tmux resolution inside tmux or when no socket was configured.
    if [[ -n ${TMUX:-} || -z ${TMUX_SOCKET:-} ]]; then
        command tmux "$@"
    else
        command tmux -L "$TMUX_SOCKET" "$@"
    fi
}

alias ta='tmux attach -t'
alias tad='tmux attach -d -t'
alias ts='tmux new-session -s'
alias to='tmux new-session -A -s'
alias tl='tmux list-sessions'

# Tmux smart session aliases
_tss_normalize_name() {
    local name="$1"

    name="${name//./_}"
    name="${name//:/_}"
    name="${name//[[:space:]]/_}"
    print -r -- "$name"
}

_tss_session_name() {
    local git_root
    local project_name
    local revision_name

    git_root=$(command git -C "$PWD" rev-parse --show-toplevel 2>/dev/null) || {
        print -u2 'tss: current directory is not in a Git repository'
        return 1
    }

    project_name=$(_tss_normalize_name "${git_root##*/}")
    revision_name=$(command git -C "$PWD" symbolic-ref --quiet --short HEAD 2>/dev/null)
    if [[ -z "$revision_name" ]]; then
        revision_name=$(command git -C "$PWD" describe --tags --exact-match HEAD 2>/dev/null)
    fi
    if [[ -z "$revision_name" ]]; then
        revision_name=$(command git -C "$PWD" rev-parse --short HEAD 2>/dev/null) || {
            print -u2 'tss: could not resolve HEAD'
            return 1
        }
    fi

    revision_name=$(_tss_normalize_name "$revision_name")
    print -r -- "$project_name/$revision_name"
}

# New tmux session with smart session name based on git
tss() {
    local session_name

    session_name=$(_tss_session_name) || return

    if tmux has-session -t "=$session_name" 2>/dev/null; then
        if [[ -n ${TMUX:-} ]]; then
            tmux switch-client -t "=$session_name"
        else
            tmux attach-session -t "=$session_name"
        fi
        return
    fi

    if [[ -n ${TMUX:-} ]]; then
        tmux new-session -d -s "$session_name" -c "$PWD" "$@" || return
        tmux switch-client -t "=$session_name"
    else
        tmux new-session -s "$session_name" -c "$PWD" "$@"
    fi
}

# New tmux session and detach with smart session name based on git
tssd() {
    local session_name
    local target

    session_name=$(_tss_session_name) || return
    if ! tmux has-session -t "=$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -c "$PWD" "$@" || return
    fi

    target="$session_name"
    if [[ -n ${TMUX:-} ]]; then
        print -r -- "Created new session: ${(qq)target}"
    else
        print -r -- "Created new session: ${(qq)target}"
    fi
}

# Tmux session launcher from command line
tp() {
    "$HOME/.config/tmux/scripts/tmux-launcher.sh" "$@"
}

# Change directory for current tmux session via the launcher
tc() {
    "$HOME/.config/tmux/scripts/tmux-launcher.sh" --change-directory
}

searchignore() {
    if [[ -e .ignore || -L .ignore ]]; then
        read -q 'REPLY?Remove existing .ignore? [y/N] ' || {
            print
            return 1
        }
        print
        rm -f .ignore || return
    fi

    cp ~/dotfiles/dotignore/searchignore .ignore
}

alias px='pi --no-session'
alias cx='codex'
cxp() {
  local prompt='$commit push'

  if (( $# )); then
    prompt+=" ${(j: :)@}"
  fi

  command codex exec \
    --ephemeral \
    -m gpt-5.6-sol \
    -c model_reasoning_effort=low \
    -c service_tier=fast \
    -- "$prompt"
}

function y() {
	YAZI_START_DIR="$PWD" command yazi "$@"
}

function ycd() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	YAZI_START_DIR="$PWD" command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	command rm -f -- "$tmp"
}

preview() {
	"$HOME/.config/zsh/scripts/quick-look.sh" "$@"
}

_rsync_excludes=(
    --exclude "__pycache__"
    --exclude "Session.vim"
    --exclude ".DS_Store"
    --exclude ".undodir"
    --exclude ".git"
    --exclude ".venv"
    --exclude ".src"
)

rpush() {
    if [ -z "$RSYNC_REMOTE" ]; then
        echo "Missing environment variable \$RSYNC_REMOTE"
        return 1
    fi

    rsync -av --progress "${_rsync_excludes[@]}" "$@" ./ "$RSYNC_REMOTE"
}

rpull() {
    if [ -z "$RSYNC_REMOTE" ]; then
        echo "Missing environment variable \$RSYNC_REMOTE"
        return 1
    fi

    rsync -av --progress "${_rsync_excludes[@]}" "$@" "$RSYNC_REMOTE" ../
}

rstatus() {
    if [ -z "$RSYNC_REMOTE" ]; then
        echo "Missing environment variable \$RSYNC_REMOTE"
        return 1
    fi

    echo "PUSH CHANGES:"
    rpush --delete -n
    echo
    echo "PULL CHANGES:"
    rpull --delete -n
}

[ -z $(command -v brew) ] || alias ctags="`brew --prefix`/bin/ctags"

# Show the resolved SSH host in the tmux pane title, use a block cursor during
# SSH, then clear the pane metadata and restore the invoking shell's cursor.
ssh() {
    local title
    local exit_code
    local saved_cursor_style="${ZSH_CURSOR_STYLE:-6}"

    if [[ -n "$TMUX_PANE" ]]; then
        title=$(command ssh -G "$@" 2>/dev/null | awk '
            $1 == "host" { host = $2 }
            $1 == "user" { user = $2 }
            $1 == "hostname" { hostname = $2 }
            END {
                if (host != "") {
                    printf "%s", host
                    exit
                }

                if (hostname == "") {
                    exit 1
                }

                if (user != "") {
                    printf "%s@%s", user, hostname
                } else {
                    printf "%s", hostname
                }
            }
        ')

        tmux set-option -p -u -t "$TMUX_PANE" @ssh_session_active 2>/dev/null || true
        tmux set-option -p -u -t "$TMUX_PANE" @ssh_session_name 2>/dev/null || true
        if [[ -n "$title" ]]; then
            tmux set-option -p -t "$TMUX_PANE" @ssh_session_active 1 2>/dev/null || true
            tmux set-option -p -t "$TMUX_PANE" @ssh_session_name "$title" 2>/dev/null || true
        fi
    fi

    zsh_set_cursor_style 2
    command ssh "$@"
    exit_code=$?
    zsh_set_cursor_style "$saved_cursor_style"

    if [[ -n "$TMUX_PANE" ]]; then
        tmux set-option -p -u -t "$TMUX_PANE" @ssh_session_active 2>/dev/null || true
        tmux set-option -p -u -t "$TMUX_PANE" @ssh_session_name 2>/dev/null || true
    fi
    return $exit_code
}
