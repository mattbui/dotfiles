let g:mapleader = ","
syntax enable
if !has('gui_running')
  set t_Co=256
endif

" use hybrid number in everymode except insert
set number relativenumber
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

set hidden
set nowrap
set encoding=utf-8
set fileencoding=utf-8
set pumheight=10
set ruler
set cursorline
set scrolloff=2
set sidescrolloff=5
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
set showtabline=2
set ignorecase
set smartcase
set noshowmode
set nobackup
set nowritebackup
set updatetime=300
set timeoutlen=300
set clipboard+=unnamedplus

filetype plugin indent on
autocmd FileType * setlocal formatoptions-=cro
cmap w!! w !sudo tee %

