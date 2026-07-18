#!/bin/sh

DOTFILES=$HOME/dotfiles
CONFIGS=$HOME/.config

mkdir -p "$CONFIGS"

link_path() {
  src=$1
  dst=$2

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    rm -rf "$dst"
  fi

  ln -s "$src" "$dst"
}

# Zsh configs
link_path "$DOTFILES/dotzsh" "$CONFIGS/zsh"

# Tmux configs
link_path "$DOTFILES/dottmux/.tmux.conf" "$HOME/.tmux.conf"
link_path "$DOTFILES/dottmux" "$CONFIGS/tmux"

# Sesh configs
mkdir -p "$CONFIGS/sesh"
link_path "$DOTFILES/others/sesh.toml" "$CONFIGS/sesh/sesh.toml"

# Git configs
link_path "$DOTFILES/dotignore/globalgitignore" "$HOME/.globalgitignore"

# Neovim configs
link_path "$DOTFILES/dotnvim" "$CONFIGS/nvim"

# Yazi configs
link_path "$DOTFILES/dotyazi" "$CONFIGS/yazi"

# revdiff configs
link_path "$DOTFILES/dotrevdiff" "$CONFIGS/revdiff"

# yabai configs
mkdir -p "$CONFIGS/yabai"
link_path "$DOTFILES/dotyabai/yabairc" "$CONFIGS/yabai/yabairc"
link_path "$DOTFILES/dotyabai/scripts" "$CONFIGS/yabai/scripts"

# skhd configs
mkdir -p "$CONFIGS/skhd"
link_path "$DOTFILES/dotyabai/skhdrc" "$CONFIGS/skhd/skhdrc"

# JankyBorders configs
mkdir -p "$CONFIGS/borders"
link_path "$DOTFILES/others/bordersrc" "$CONFIGS/borders/bordersrc"

# Alacritty configs
mkdir -p "$CONFIGS/alacritty"
link_path "$DOTFILES/others/alacritty.toml" "$CONFIGS/alacritty/alacritty.toml"

# Ghostty configs
mkdir -p "$CONFIGS/ghostty"
link_path "$DOTFILES/others/ghostty.config" "$CONFIGS/ghostty/config"
