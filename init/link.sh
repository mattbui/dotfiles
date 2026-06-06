#!/bin/sh

DOTFILES=$HOME/dotfiles
CONFIGS=$HOME/.config

[ ! -d $CONFIGS ] && mkdir -p $CONFIGS

# Zsh configs
[ -d $CONFIGS/zsh ] || [ -h $CONFIGS/zsh ] && rm -rf $CONFIGS/zsh
ln -s $DOTFILES/dotzsh $CONFIGS/zsh

# Tmux configs
[ -f $HOME/.tmux.conf ] || [ -h $HOME/.tmux.conf ] && rm $HOME/.tmux.conf
ln -s $DOTFILES/dottmux/.tmux.conf $HOME/.tmux.conf
[ -d $CONFIGS/tmux ] || [ -h $CONFIGS/tmux ] && rm -rf $CONFIGS/tmux
ln -s $DOTFILES/dottmux $CONFIGS/tmux

[ -f $HOME/.gitignore_global ] || [ -h $HOME/.gitignore_global ] && rm $HOME/.gitignore_global
ln -s $DOTFILES/dotignore/.gitignore_global $HOME/.gitignore_global

# Neovim configs
[ -d $CONFIGS/nvim ] || [ -h $CONFIGS/nvim ] && rm -rf $CONFIGS/nvim
ln -s $DOTFILES/dotnvim $CONFIGS/nvim

# lf configs
[ -d $CONFIGS/lf ] || [ -h $CONFIGS/lf ] && rm -rf $CONFIGS/lf
ln -s $DOTFILES/dotlf $CONFIGS/lf

# direnv configs
[ -d $CONFIGS/direnv ] || [ -h $CONFIGS/direnv ] && rm -rf $CONFIGS/direnv
ln -s $DOTFILES/dotdirenv $CONFIGS/direnv

# revdiff configs
[ -d $CONFIGS/revdiff ] || [ -h $CONFIGS/revdiff ] && rm -rf $CONFIGS/revdiff
ln -s $DOTFILES/dotrevdiff $CONFIGS/revdiff

# yabai configs
[ ! -d $CONFIGS/yabai ] && mkdir -p $CONFIGS/yabai
[ -f $CONFIGS/yabai/yabairc ] || [ -h $CONFIGS/yabai/yabairc ] && rm $CONFIGS/yabai/yabairc
[ -d $CONFIGS/yabai/scripts ] || [ -h $CONFIGS/yabai/scripts ] && rm -rf $CONFIGS/yabai/scripts
ln -s $DOTFILES/dotyabai/yabairc $CONFIGS/yabai/yabairc
ln -s $DOTFILES/dotyabai/scripts $CONFIGS/yabai/scripts

# skhd configs
[ ! -d $CONFIGS/skhd ] && mkdir -p $CONFIGS/skhd
[ -f $CONFIGS/skhd/skhdrc ] || [ -h $CONFIGS/skhd/skhdrc ] && rm $CONFIGS/skhd/skhdrc
ln -s $DOTFILES/dotyabai/skhdrc $CONFIGS/skhd/skhdrc

# JankyBorders configs
[ ! -d $CONFIGS/borders ] && mkdir -p $CONFIGS/borders
[ -f $CONFIGS/borders/bordersrc ] || [ -h $CONFIGS/borders/bordersrc ] && rm $CONFIGS/borders/bordersrc
ln -s $DOTFILES/others/bordersrc $CONFIGS/borders/bordersrc

# Alacritty configs
[ ! -d $CONFIGS/alacritty ] && mkdir -p $CONFIGS/alacritty
[ -f $CONFIGS/alacritty/alacritty.yml ] || [ -h $CONFIGS/alacritty/alacritty.yml ] && rm $CONFIGS/alacritty/alacritty.yml
[ -f $CONFIGS/alacritty/alacritty.toml ] || [ -h $CONFIGS/alacritty/alacritty.toml ] && rm $CONFIGS/alacritty/alacritty.toml
ln -s $DOTFILES/others/alacritty.toml $CONFIGS/alacritty/alacritty.toml
