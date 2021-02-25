#!/bin/bash

# Get dotfiles
DOTFILES=$HOME/dotfiles
git clone https://github.com/mattbui/dotfiles.git $DOTFILES

# Zshell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

cp $DOTFILES/dotzsh/.zshrc $HOME/.zshrc

bash $DOTFILES/dotsh/dotlink.sh

# Git
git config --global user.email matthew@cinnamon.is
git config --global user.username mattbui
# git config --global branch.autosetuprebase always

git config --global core.excludesfile $HOME/.gitignore_global

# git config --global user.signingkey <key_id>
git config --global commit.gpgsign true

bash $DOTFILES/dotsh/conda_setup.sh

# use this if cannot change default shell to zsh
printf "Done intialization"
printf "To use zsh as default shell use:\n\tchsh -s \$(which zsh)\nor\n\techo \"exec zsh\" >> $HOME/.bashrc\n"
