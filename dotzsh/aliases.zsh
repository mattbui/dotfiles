# My aliases

# conda
alias ca='conda activate'
alias cde='conda deactivate'
alias ci='conda install'
alias cc='conda create -n'
alias cl='conda env list'
alias cr='conda remove'
alias cra='conda remove --all -n'

# workaround when using e command inside floaterm/vim
[ -z $VIMRUNTIME ] && alias e=$EDITOR || alias e=floaterm
alias v=$VISUAL

alias fa='alias | fzf'  # fuzzy find alias
alias cheat='cht.sh'

alias rpush='[ -z $RSYNC_REMOTE ] && echo "Missing environment variable \$RSYNC_REMOTE" || rsync -av --exclude "__pycache__" --exclude "Session.vim" --exclude ".undodir" --exclude ".git" ./ $RSYNC_REMOTE'
alias rpull='[ -z $RSYNC_REMOTE ] && echo "Missing environment variable \$RSYNC_REMOTE" || rsync -av --exclude "__pycache__" --exclude "Session.vim" --exclude ".undodir" --exclude ".git" $RSYNC_REMOTE ../'
alias rstatus='[ -z $RSYNC_REMOTE ] && echo "Missing environment variable \$RSYNC_REMOTE" || (echo "PUSH CHANGES:" && rpush --delete -n && echo "PULL CHANGES:" && rpull --delete -n)'

alias ppip='python -m pip'
alias pipython='python -c "import IPython; IPython.terminal.ipapp.launch_new_instance()"'

[ -z $(command -v brew) ] || alias ctags="`brew --prefix`/bin/ctags"

ssh() {
    local title
    local status

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
    status=$?

    [[ -n "$TMUX" && -n "$title" ]] && tmux select-pane -T ""
    return $status
}
