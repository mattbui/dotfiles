#!/bin/sh

# Get dotfiles
DOTFILES=$HOME/dotfiles
git clone https://github.com/mattbui/dotfiles.git $DOTFILES

sh $DOTFILES/init/link.sh  # link configs from dotfiles

# Zshell
# Add "source $HOME/.config/zsh/init.zsh" at the begining of $HOME/.zshrc
(echo "source $HOME/.config/zsh/init.zsh" &&\
    cat $HOME/.zshrc 2>/dev/null) > $HOME/.zshrc_tmp\
    && mv $HOME/.zshrc_tmp $HOME/.zshrc

curl -L git.io/antigen > $HOME/.antigen.zsh  # antigen as zsh plugins manager


sh $DOTFILES/init/git.sh  # git configs
# sh $DOTFILES/init/conda.sh  # setup miniconda

# use this if cannot change default shell to zsh
printf "Done intialization"
printf "To use zsh as default shell use:\n\tchsh -s \$(which zsh)\nor\n\techo \"exec zsh\" >> $HOME/.bashrc\n"

