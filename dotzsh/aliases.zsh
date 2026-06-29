# My aliases

# workaround when using e command inside floaterm/vim
[ -z $VIMRUNTIME ] && alias e=$EDITOR || alias e=floaterm
alias v=$VISUAL

alias fa='alias | fzf'  # fuzzy find alias
alias cheat='cht.sh'
alias lnignore='ln -s ~/dotfiles/dotignore/.ignore_search .ignore'

alias px='pi --no-session'

picommit() {
    local args="$*"
    pi --no-session "/commit${args:+ $args}"
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

alias ppip='python -m pip'
alias pipython='python -c "import IPython; IPython.terminal.ipapp.launch_new_instance()"'

[ -z $(command -v brew) ] || alias ctags="`brew --prefix`/bin/ctags"

ssh() {
    local title
    local exit_code

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

    printf '\e[2 q'
    command ssh "$@"
    exit_code=$?
    printf '\e[6 q'

    if [[ -n "$TMUX_PANE" ]]; then
        tmux set-option -p -u -t "$TMUX_PANE" @ssh_session_active 2>/dev/null || true
        tmux set-option -p -u -t "$TMUX_PANE" @ssh_session_name 2>/dev/null || true
    fi
    return $exit_code
}

codex() {
    if [[ -n "$TMUX_PANE" ]]; then
        tmux set-option -p -t "$TMUX_PANE" @codex_session_active 1 2>/dev/null || true
    fi

    command codex "$@"
    local exit_code=$?

    if [[ -n "$TMUX_PANE" ]]; then
        tmux set-option -p -u -t "$TMUX_PANE" @codex_session_active 2>/dev/null || true
    fi
    return $exit_code
}
