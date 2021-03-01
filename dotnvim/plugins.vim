" auto-install vim-plug
if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  "autocmd VimEnter * PlugInstall
  "autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

call plug#begin('~/.config/nvim/autoload/plugged')
    
    " Usefull utilities
    Plug 'sheerun/vim-polyglot'     " Better Syntax Support 
    Plug 'jiangmiao/auto-pairs'     " Auto pairs for '(' '[' '{'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-commentary'
    Plug 'Yggdroot/indentLine'
    Plug 'unblevable/quick-scope'   " Faster moving accross line
    Plug 'airblade/vim-rooter'      " Smartly change project directory when open file
    Plug 'ptzz/lf.vim'
    Plug 'voldikss/vim-floaterm'   

    " fzf
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'

    " Tmux integration
    Plug 'edkolev/tmuxline.vim'
    Plug 'christoomey/vim-tmux-navigator'

    " Coc plugin for intellisense
    Plug 'neoclide/coc.nvim', {'branch': 'release'}

    " Theme
    Plug 'ayu-theme/ayu-vim'
    Plug 'sonph/onehalf', {'rtp': 'vim/'}
    Plug 'lifepillar/vim-wwdc17-theme'

    " Light line
    Plug 'itchyny/lightline.vim'
    Plug 'mengelbrecht/lightline-bufferline'

call plug#end()

