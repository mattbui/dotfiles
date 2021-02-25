let g:mapleader = ","
syntax enable
set hidden
" set nowrap
set encoding=utf-8
set fileencoding=utf-8
set pumheight=10
set ruler
set cursorline
if !has('gui_running')
  set t_Co=256
endif
set iskeyword+=-
set mouse=a
set splitbelow
set splitright
set conceallevel=0
set tabstop=4
set shiftwidth=4
set smarttab
set expandtab
set smartindent
set autoindent
set laststatus=2
set number
set showtabline=2
set ignorecase
set smartcase
set noshowmode
set nobackup
set nowritebackup
set updatetime=300
set clipboard+=unnamedplus

filetype plugin indent on
autocmd FileType * setlocal formatoptions-=cro
cmap w!! w !sudo tee %

