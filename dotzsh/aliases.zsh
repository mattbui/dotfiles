# My aliases

# workaround when using e command inside floaterm/vim
[ -z $VIMRUNTIME ] && alias e=$EDITOR || alias e=floaterm
alias v=$VISUAL

alias fa='alias | fzf'  # fuzzy find alias
alias cheat='cht.sh'

alias rpush='[ -z $RSYNC_REMOTE ] && echo "Missing environment variable \$RSYNC_REMOTE" || rsync -av --exclude "__pycache__" --exclude "Session.vim" --exclude ".undodir" --exclude ".git" --exclude ".venv" ./ $RSYNC_REMOTE'
alias rpull='[ -z $RSYNC_REMOTE ] && echo "Missing environment variable \$RSYNC_REMOTE" || rsync -av --exclude "__pycache__" --exclude "Session.vim" --exclude ".undodir" --exclude ".git" --exclude ".venv" $RSYNC_REMOTE ../'
alias rstatus='[ -z $RSYNC_REMOTE ] && echo "Missing environment variable \$RSYNC_REMOTE" || (echo "PUSH CHANGES:" && rpush --delete -n && echo "PULL CHANGES:" && rpull --delete -n)'

alias ppip='python -m pip'
alias pipython='python -c "import IPython; IPython.terminal.ipapp.launch_new_instance()"'

[ -z $(command -v brew) ] || alias ctags="`brew --prefix`/bin/ctags"

ssh() {
    local title
    local exit_code

    if [[ -n "$TMUX" ]]; then
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

        [[ -n "$title" ]] && tmux select-pane -T "$title"
    fi

    command ssh "$@"
    exit_code=$?

    [[ -n "$TMUX" && -n "$title" ]] && tmux select-pane -T ""
    return $exit_code
}

codex() {
    [[ -n "$TMUX_PANE" ]] && tmux select-pane -t "$TMUX_PANE" -T ""

    CODEX_TMUX_TITLE_HOOK=1 command codex "$@"
    local exit_code=$?

    [[ -n "$TMUX_PANE" ]] && tmux select-pane -t "$TMUX_PANE" -T ""
    return $exit_code
}
