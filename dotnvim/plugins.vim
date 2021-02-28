" auto-install vim-plug
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  "autocmd VimEnter * PlugInstall
  "autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/autoload/plugged')

    " Better Syntax Support
    Plug 'sheerun/vim-polyglot'
    " Auto pairs for '(' '[' '{'
    Plug 'jiangmiao/auto-pairs'
    " Manage surrond objects
    Plug 'tpope/vim-surround'
    " Commentary
    Plug 'tpope/vim-commentary'
    " Coc for intellisense
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    " Theme
    Plug 'ayu-theme/ayu-vim'
    " Intent line
    Plug 'Yggdroot/indentLine'
    " Light line
    Plug 'itchyny/lightline.vim'
    " Buffer line
    Plug 'mengelbrecht/lightline-bufferline'
    " Faster moving across line
    Plug 'unblevable/quick-scope'
    " Tmux integration
    Plug 'edkolev/tmuxline.vim'
    Plug 'christoomey/vim-tmux-navigator'
call plug#end()

