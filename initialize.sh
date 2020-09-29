# Initialize commands for new computer

# Zshell
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
cp .zshrc ~/
cp .p10k.zsh ~/

# use this if cannot change default shell to zsh
# echo "exec zsh" >> ~/.bashrc

# Git
# mkdir ~/.ssh
# add git key if needed
# cp git.key ~/.ssh
# gpg --import gpg_secret_keys
git config --global user.email matthew@cinnamon.is
git config --global user.name "Bui Cong Minh"
git config --global user.username mattbui
git config --global branch.autosetuprebase always

cp .gitignore_global ~/
git config --global core.excludesfile ~/.gitignore_global

# git config --global user.signingkey 24AE1F8C294EE08C
git config --global commit.gpgsign true