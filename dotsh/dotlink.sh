#!/bin/bash

DOTFILES=$HOME/dotfiles

# Zsh configs
[[ -f $HOME/.aliases.sh ]] && rm $HOME/.aliases.zsh
ln -s $DOTFILES/dotzsh/.aliases.zsh $HOME/.aliases.zsh

[[ -f $HOME/.p10k.sh ]] && rm $HOME/.p10k.zsh
ln -s $DOTFILES/dotzsh/.p10k.zsh $HOME/.p10k.zsh

[[ -f $HOME/.start_ssh_agent.sh ]] && rm $HOME/.start_ssh_agent.zsh
ln -s $DOTFILES/dotzsh/.start_ssh_agent.zsh $HOME/.start_ssh_agent.zsh

# Tmux configs
[[ -f $HOME/.tmux.conf ]] && rm $HOME/.tmux.conf
ln -s $DOTFILES/dottmux/.tmux.conf $HOME/.tmux.conf
[[ -f $HOME/.tmux-line.conf ]] && rm $HOME/.tmux-line.conf
ln -s $DOTFILES/dottmux/.tmux-line.conf $HOME/.tmux-line.conf

[[ -f $HOME/.gitignore_global ]] && rm $HOME/.gitignore_global
ln -s $DOTFILES/dotignore/.gitignore_global $HOME/.gitignore_global

# Neovim configs
[[ ! -d $HOME/.config ]] && mkdir -p $HOME/.config
[[ -d $HOME/.config/nvim ]] && rm -rf $HOME/.config/nvim
ln -s $DOTFILES/dotnvim $HOME/.config/nvim

