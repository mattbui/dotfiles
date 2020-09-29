# Initialize commands for new servers

# Zshell
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
cp .zshrc ~/
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
echo "exec zsh" >> ~/.bashrc

# Git
mkdir ~/.ssh
cp cinnamon_git.key ~/.ssh
gpg --import gpg_secret_keys
git config --global user.email matthew@cinnamon.is
git config --global user.name matt_Cin
git config --global user.signingkey 24AE1F8C294EE08C
git config --global commit.gpgsign true