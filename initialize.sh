#!/bin/sh

# Get dotfiles
DOTFILES=$HOME/dotfiles
git clone https://github.com/mattbui/dotfiles.git $DOTFILES

sh $DOTFILES/init/link.sh  # link configs from dotfiles

# Zshell
# Add "source $HOME/.config/zsh/init.zsh" at the begining of $HOME/.zshrc
[ ! -f  $HOME/.zshrc ] && touch $HOME/.zshrc
(echo "source $HOME/.config/zsh/init.zsh" &&\
    cat $HOME/.zshrc 2>/dev/null) > $HOME/.zshrc_tmp\
    && mv $HOME/.zshrc_tmp $HOME/.zshrc

sh $DOTFILES/init/git.sh  # git configs

# Setup essential packages
case "$(uname -s)" in
    Linux*) [ "$EUID" -ne 0 ] || sh $DOTFILES/init/apt_install.sh;;
    Darwin*) sh $DOTFILES/init/mac_install.sh;;
    *) echo "UNKNOWN:$(uname -a)";;
esac
sh $DOTFILES/init/install.sh

# use this if cannot change default shell to zsh
printf "Done intialization"
printf "To use zsh as default shell use:\n\tchsh -s \$(which zsh)\nor\n\techo \"exec zsh\" >> $HOME/.bashrc\n"
