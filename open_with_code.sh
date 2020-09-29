# my fun script to quickly open projects/files with vscode

WORK_DIR="/media/matthew/Data/gdrive/works"
CIN_DIR="/media/matthew/Data/gdrive/works/cinnamon"

if [ -z "$1" ]; then
    code
else
    if [ -d "$1" ]; then
        code "$1"
    elif [ -d "$HOME/$1" ]; then
        code "$HOME/$1"
    elif [ -d "$WORK_DIR/$1" ]; then
        code "$WORK_DIR/$1"
    elif [ -d "$CIN_DIR/$1" ]; then
        code "$CIN_DIR/$1"
    else
        code "$1"
    fi
fi
