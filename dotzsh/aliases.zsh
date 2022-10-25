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

alias rpush='[ -z $RSYNC_REMOTE ] && echo "Missing environment variable \$RSYNC_REMOTE" || rsync -av --exclude "__pycache__" --exclude "Session.vim" --exclude ".undodir" ./ $RSYNC_REMOTE'
alias rpull='[ -z $RSYNC_REMOTE ] && echo "Missing environment variable \$RSYNC_REMOTE" || rsync -av --exclude "__pycache__" --exclude "Session.vim" --exclude ".undodir" $RSYNC_REMOTE ../'
alias rstatus='[ -z $RSYNC_REMOTE ] && echo "Missing environment variable \$RSYNC_REMOTE" || (echo "PUSH CHANGES:" && rpush --delete -n && echo "PULL CHANGES:" && rpull --delete -n)'

alias ppip='python -m pip'
alias pipython='python -c "import IPython; IPython.terminal.ipapp.launch_new_instance()"'
