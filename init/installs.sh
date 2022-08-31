#!/bin/sh
if ! command -v conda &> /dev/null
then
    case "$(uname -s)" in
        Linux*)
            case "$(uname -m)" in
                x86_64) conda_url=https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh;;
                i686 | i386) conda_url=https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86.sh;;
                *) echo "UNKNOWN:$(uname -a)";;
            esac
            ;;
        Darwin*) conda_url=https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh;;
        *) echo "UNKNOWN:$(uname -a)";;
    esac

    if [ ! -z $conda_url ]; then
        echo "Installing conda from: $conda_url"
        wget -O $HOME/miniconda_installer.sh $conda_url
        zsh $HOME/miniconda_installer.sh -b
        conda_path=$HOME/miniconda3
        eval "$(${conda_path}/bin/conda shell.zsh hook)"
        conda init zsh
    fi
fi

if ! command -v fzf &> /dev/null
then
    echo "Installing Fzf"
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install --all
fi

if ! command -v antigen &> /dev/null
then
    echo "Installing Antigen"
    curl -L git.io/antigen > $HOME/.antigen.zsh  # antigen as zsh plugins manager
fi

if ! command -v lf &> /dev/null
then
    echo "Installing Lf"
    latest_release=$(curl -L -s -H 'Accept: application/json' https://github.com/gokcehan/lf/releases/latest)
    latest_version=$(echo $latest_release | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
    case "$(uname -s)" in
        Linux*)
            case "$(uname -m)" in
                x86_64) artifact_url="https://github.com/gokcehan/lf/releases/download/$latest_version/lf-linux-amd64.tar.gz";;
                i686 | i386) artifact_url="https://github.com/gokcehan/lf/releases/download/$latest_version/lf-linux-386.tar.gz";;
                *) echo "UNKNOWN:$(uname -a)";;
            esac
            ;;
        Darwin*) artifact_url="https://github.com/gokcehan/lf/releases/download/$latest_version/lf-darwin-amd64.tar.gz";;
        *) echo "UNKNOWN:$(uname -a)";;
    esac

    if [ ! -z $artifact_url ]; then
        echo "Installing LF from: $artifact_url"
        wget -O $HOME/lf.tar.gz $artifact_url
        [! -d $HOME/bin] && mkdir $HOME/bin && echo "export PATH=\$PATH:$HOME/bin" >> .zshrc
        tar xvf $HOME/lf.tar.gz -C $HOME/bin
        chmod +x $HOME/bin/lf
    fi
fi

if ! command -v direnv &> /dev/null
then
    echo "Installing Direnv"
    [! -d $HOME/bin] && mkdir $HOME/bin
    export bin_path=$HOME/bin
    curl -sfL https://direnv.net/install.sh | bash
fi

if ! command -v nvim &> /dev/null
then
    echo "Installing NeoVim"
    case "$(uname -s)" in
        Linux*) artifact_url=https://github.com/neovim/neovim/releases/download/stable/nvim-linux-64.tar.gz && bin_path=nvim-linux64/bin;;
        Darwin*) artifact_url=https://github.com/neovim/neovim/releases/download/stable/nvim-macos.tar.gz && bin_path=nvim-macos/bin;;
        *) echo "UNKNOWN:$(uname -a)";;
    esac
    if [ ! -z $artifact_url ]; then
        echo "Installing NeoVim from: $artifact_url"
        wget -O $HOME/nvim.tar.gz $artifact_url

        tar xzvf nvim.tar.gz -C $HOME
        echo "export PATH=\$PATH:$HOME/$bin_path" >> .zshrc
    fi
fi
