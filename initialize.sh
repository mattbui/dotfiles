# Initialize commands for new computer
positional=()
while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
	--conda_path)
    conda_path="$2"
    shift # past argument
    shift # past value
    ;;
esac
done
set -- "${positional[@]}" # restore positional parameter

echo "Conda path: ${conda_path}"

# Get dotfiles
dotfiles=$HOME/dotfiles
git clone https://github.com/mattbui/dotfiles.git $dotfiles

# Zshell
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

platform="$(uname -s)"
echo "Platform: ${platform}"
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
# mkdir $HOME/.ssh
# add git key if needed
# cp git.key $HOME/.ssh
# gpg --import gpg_secret_keys
git config --global user.email matthew@cinnamon.is
git config --global user.username mattbui
# git config --global branch.autosetuprebase always

ln -s $dotfiles/.gitignore_global $HOME/.gitignore_global
git config --global core.excludesfile $HOME/.gitignore_global

# git config --global user.signingkey <key_id>
git config --global commit.gpgsign true

# Initialize conda
if [[ -z $conda_path]]; then
    source "$conda_path/bin/activate"
    conda init
fi
