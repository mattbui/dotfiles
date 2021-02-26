#!/bin/bash

DOTFILES=$HOME/dotfiles
CONFIGS=$HOME/.config

[[ ! -d $CONFIGS ]] && mkdir -p $CONFIGS

# Zsh configs
[[ -d $CONFIGS/zsh || -h $CONFIGS/zsh ]] && rm -rf $CONFIGS/zsh
ln -s $DOTFILES/dotzsh $CONFIGS/zsh

# Tmux configs
[[ -f $HOME/.tmux.conf || -h $HOME/.tmux.conf ]] && rm $HOME/.tmux.conf
ln -s $DOTFILES/dottmux/.tmux.conf $HOME/.tmux.conf
[[ -f $HOME/.tmux-mappings.conf || -h $HOME/.tmux-mappings.conf ]] && rm $HOME/.tmux-mappings.conf
ln -s $DOTFILES/dottmux/.tmux-mappings.conf $HOME/.tmux-mappings.conf
[[ -f $HOME/.tmux-line.conf || -h $HOME/.tmux-line.conf ]] && rm $HOME/.tmux-line.conf
ln -s $DOTFILES/dottmux/.tmux-line.conf $HOME/.tmux-line.conf
[[ -f $HOME/.tmux-vim-nav.conf || -h $HOME/.tmux-vim-nav.conf ]] && rm $HOME/.tmux-vim-nav.conf
ln -s $DOTFILES/dottmux/.tmux-vim-nav.conf $HOME/.tmux-vim-nav.conf
[[ -f $HOME/.tmux-pane.conf || -h $HOME/.tmux-pane.conf ]] && rm $HOME/.tmux-pane.conf
ln -s $DOTFILES/dottmux/.tmux-pane.conf $HOME/.tmux-pane.conf

[[ -f $HOME/.gitignore_global || -h $HOME/.gitignore_global ]] && rm $HOME/.gitignore_global
ln -s $DOTFILES/dotignore/.gitignore_global $HOME/.gitignore_global

# Neovim configs
[[ -d $CONFIGS/nvim || -h $CONFIGS/nvim ]] && rm -rf $CONFIGS/nvim
ln -s $DOTFILES/dotnvim $CONFIGS/nvim

