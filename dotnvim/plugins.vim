call plug#begin(stdpath('data') . '/plugged')
    
    " Usefull utilities
    Plug 'sheerun/vim-polyglot'     " Better Syntax Support 
    Plug 'jiangmiao/auto-pairs'     " Auto pairs for '(' '[' '{'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-commentary'
    Plug 'Yggdroot/indentLine'
    " Plug 'unblevable/quick-scope'   " Faster moving accross line
    Plug 'airblade/vim-rooter'      " Smartly change project directory when open file
    Plug 'ptzz/lf.vim'
    Plug 'voldikss/vim-floaterm'   
    Plug 'easymotion/vim-easymotion'

    " fzf
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'

    " Tmux integration
    Plug 'edkolev/tmuxline.vim'
    Plug 'christoomey/vim-tmux-navigator'

    " Coc plugin for intellisense
    Plug 'neoclide/coc.nvim', {'branch': 'release'}

    " Theme
    " Plug 'ayu-theme/ayu-vim'
    " Plug 'sonph/onehalf', {'rtp': 'vim/'}
    Plug 'lifepillar/vim-wwdc17-theme'

    " Light line
    Plug 'itchyny/lightline.vim'
    Plug 'mengelbrecht/lightline-bufferline'

call plug#end()

