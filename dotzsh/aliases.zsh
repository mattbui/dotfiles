# My aliases

alias e=$EDITOR
alias v=$VISUAL
alias y='yazi'
alias cd='z'
alias 'cd!'='builtin cd'

alias fa='alias | fzf'  # fuzzy find alias
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

function ycd() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
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
