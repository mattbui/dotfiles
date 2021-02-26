#!/bin/zsh

# Get dotfiles
DOTFILES=$HOME/dotfiles
git clone https://github.com/mattbui/dotfiles.git $DOTFILES

# Zshell
echo "source $HOME/.config/zsh/init.zsh" >> $HOME/.zshrc
curl -L git.io/antigen > $HOME/.antigen.zsh  # antigen as zsh plugins manager
zsh $DOTFILES/dotsh/dotlink.sh  # link configs from dotfiles


zsh $DOTFILES/dotsh/git.sh  # git configs
zsh $DOTFILES/dotsh/conda_setup.sh  # setup miniconda

# use this if cannot change default shell to zsh
printf "Done intialization"
printf "To use zsh as default shell use:\n\tchsh -s \$(which zsh)\nor\n\techo \"exec zsh\" >> $HOME/.bashrc\n"

