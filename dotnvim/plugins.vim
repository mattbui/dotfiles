call plug#begin(stdpath('data') . '/plugged')
    
    " Usefull utilities
    Plug 'sheerun/vim-polyglot' " Better Syntax Support
    Plug 'jiangmiao/auto-pairs' " Auto pairs for '(' '[' '{'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-commentary'
    Plug 'Yggdroot/indentLine'
    Plug 'airblade/vim-rooter'  " Smartly change project directory when open file
    Plug 'ptzz/lf.vim'          " Need to be loaded before floaterm
    Plug 'voldikss/vim-floaterm'   
    Plug 'easymotion/vim-easymotion'
    Plug 'mhinz/vim-startify'
    Plug 'liuchengxu/vim-which-key'
    Plug 'junegunn/vim-easy-align'
    Plug 'ryanoasis/vim-devicons'
    Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}

    " git integration
    Plug 'tpope/vim-fugitive'

    " fzf
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'

    " Tmux integration
    " Plug 'edkolev/tmuxline.vim'
    Plug 'sainnhe/tmuxline.vim'
    Plug 'christoomey/vim-tmux-navigator'

    " Coc plugin for intellisense
    Plug 'neoclide/coc.nvim', {'branch': 'release'}

    " Theme
    " Plug 'ayu-theme/ayu-vim'
    " Plug 'sonph/onehalf', {'rtp': 'vim/'}
    " Plug 'lifepillar/vim-wwdc17-theme'
    Plug 'sainnhe/edge'

    " Light line
    Plug 'itchyny/lightline.vim'
    Plug 'mengelbrecht/lightline-bufferline'
    Plug 'josa42/vim-lightline-coc'

call plug#end()

