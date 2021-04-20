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
alias ipython='python -c "import IPython; IPython.terminal.ipapp.launch_new_instance()"'
alias ipython3='python3 -c "import IPython; IPython.terminal.ipapp.launch_new_instance()"'
