if ! command -v brew &> /dev/null
then
    echo "INSTALLING HOMEBREW"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -z $(command -v zsh) ] && brew install zsh
[ -z $(command -v yazi) ] && brew install yazi
[ -z $(command -v 7zz) ] && brew install sevenzip
[ -z $(command -v tmux) ] && brew install tmux
[ -z $(command -v nvim) ] && brew install nvim
[ -z $(command -v direnv) ] && brew install direnv
[ -z $(command -v fzf) ] && brew install fzf
[ -z $(command -v ripgrep) ] && brew install ripgrep
