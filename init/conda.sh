#!/bin/zsh

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

echo "Conda installer URL: $conda_url"

if [[ ! -z $conda_url ]]; then
    wget -O $HOME/miniconda_installer.sh $conda_url
    zsh $HOME/miniconda_installer.sh -b
    conda_path=$HOME/miniconda3
    eval "$(${conda_path}/bin/conda shell.zsh hook)"
    conda init zsh
fi
