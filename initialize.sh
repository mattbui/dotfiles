platform="$(uname -s)"
echo "Platform: ${platform}"

# Get dotfiles
dotfiles=$HOME/dotfiles
git clone https://github.com/mattbui/dotfiles.git $dotfiles

# Zshell
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

case "${platform}" in
    Linux*) cp $dotfiles/linux.zshrc $HOME/.zshrc;;
    Darwin*) cp $dotfiles/mac.zshrc $HOME/.zshrc;;
    *) echo "UNKNOWN:${platform}"
esac
done

ln -s $dotfiles/.aliases.zsh $HOME/.aliases.zsh
ln -s $dotfiles/.p10k.zsh $HOME/.p10k.zsh

# use this if cannot change default shell to zsh
# echo "exec zsh" >> $HOME/.bashrc

# Tmux configs
ln -s $dotfiles/.tmux.conf $HOME/.tmux.conf

# Git
git config --global user.email matthew@cinnamon.is
git config --global user.username mattbui
# git config --global branch.autosetuprebase always

ln -s $dotfiles/.gitignore_global $HOME/.gitignore_global
git config --global core.excludesfile $HOME/.gitignore_global

# git config --global user.signingkey <key_id>
git config --global commit.gpgsign true

# Setup conda
case "${platform}" in
    Linux*) conda_url=https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    Darwin*) conda_url=https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
    *) echo "UNKNOWN:${platform}"
esac
done

if [[ -z $conda_url ]]; then
    wget -O $HOME/miniconda_installer.sh $conda_url
    bash $HOME/miniconda_installer.sh -b
    conda_path=$HOME/miniconda3
fi

if [[ -z $conda_path]]; then
    eval "$(${conda_path}/bin/conda shell.zsh hook)"
    conda init zsh
fi
