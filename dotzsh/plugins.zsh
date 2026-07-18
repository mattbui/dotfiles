source $HOME/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle extract
antigen bundle tmux

antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle z-shell/F-Sy-H --branch=main

# Tell Antigen that you're done.
antigen apply
