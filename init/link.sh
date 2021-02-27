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
[[ -d $CONFIGS/tmux || -h $CONFIGS/tmux ]] && rm -rf $CONFIGS/tmux
ln -s $DOTFILES/dottmux $CONFIGS/tmux

[[ -f $HOME/.gitignore_global || -h $HOME/.gitignore_global ]] && rm $HOME/.gitignore_global
ln -s $DOTFILES/dotignore/.gitignore_global $HOME/.gitignore_global

# Neovim configs
[[ -d $CONFIGS/nvim || -h $CONFIGS/nvim ]] && rm -rf $CONFIGS/nvim
ln -s $DOTFILES/dotnvim $CONFIGS/nvim

