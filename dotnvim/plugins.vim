call plug#begin(stdpath('data') . '/plugged')

    " Usefull utilities
    Plug 'sheerun/vim-polyglot' " Better Syntax Support
    Plug 'jiangmiao/auto-pairs' " Auto pairs for '(' '[' '{'
    Plug 'machakann/vim-sandwich'
    Plug 'airblade/vim-rooter'  " Smartly change project directory when open file
    Plug 'ptzz/lf.vim'          " Need to be loaded before floaterm
    Plug 'voldikss/vim-floaterm'
    Plug 'thaerkh/vim-workspace'
    Plug 'easymotion/vim-easymotion'
    Plug 'liuchengxu/vim-which-key'
    Plug 'junegunn/vim-easy-align'
    Plug 'ryanoasis/vim-devicons'
    Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
    Plug 'mzlogin/vim-markdown-toc'
    Plug 'honza/vim-snippets'
    Plug 'heavenshell/vim-pydocstring'
    Plug 'lukas-reineke/indent-blankline.nvim'
    Plug 'karb94/neoscroll.nvim'

    " Tabbar
    Plug 'kyazdani42/nvim-web-devicons'
    Plug 'romgrk/barbar.nvim', {'branch': 'v1.5.0'}

    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

    " ipynb support
    Plug 'jpalardy/vim-slime'
    Plug 'hanschen/vim-ipython-cell', { 'for': 'python' }
    Plug 'mattbui/jupytext.vim', { 'branch': 'jupytext_opts' }

    " tpope's goodies
    Plug 'tpope/vim-eunuch'
    Plug 'tpope/vim-commentary'
    Plug 'tpope/vim-fugitive'

    " fzf
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'

    " Tmux integration
    " Plug 'edkolev/tmuxline.vim'
    Plug 'sainnhe/tmuxline.vim'  " enable true color for tmux line
    Plug 'christoomey/vim-tmux-navigator'

    " Coc plugin for intellisense
    Plug 'neoclide/coc.nvim', {'branch': 'release'}

    " Theme
    " Plug 'ayu-theme/ayu-vim'
    " Plug 'sonph/onehalf', {'rtp': 'vim/'}
    " Plug 'lifepillar/vim-wwdc17-theme'
    " Plug 'sainnhe/edge'
    Plug 'arcticicestudio/nord-vim'
    Plug 'folke/tokyonight.nvim'
    Plug 'folke/tokyonight.nvim'
    Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
    " Plug 'shaunsingh/nord.nvim'


    " Light line
    Plug 'itchyny/lightline.vim'
    Plug 'majutsushi/tagbar'
    " Plug 'mengelbrecht/lightline-bufferline'
    Plug 'josa42/vim-lightline-coc'

call plug#end()
