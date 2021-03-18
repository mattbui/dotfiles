let g:mapleader = " "

set background=light
filetype plugin indent on

syntax enable
if !has('gui_running')
  set t_Co=256
endif

" use hybrid number in everymode except insert
set number relativenumber
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
augroup END

set signcolumn=yes             " Always show sign column
set fillchars+=vert:\          " Set vertical splitting char to space
set hidden
set nowrap                     " Disable line wrap
set encoding=utf-8 fileencoding=utf-8
set pumheight=10               " Pop up menu smaller
set ruler                      " Show line & column number of cursor
set cursorline                 " Highlight the current cursor line
set scrolloff=2 sidescrolloff=5
set iskeyword+=-               " Treat dash as a text object
set mouse=a
set splitbelow splitright      " Always split to right below
set tabstop=4 shiftwidth=4
set smarttab expandtab smartindent autoindent
set laststatus=2 showtabline=2 " Always show tabline & statusline
set ignorecase smartcase       " Better search
set noshowmode
set nobackup nowritebackup
set updatetime=300 timeoutlen=300
set shortmess+=c
set clipboard+=unnamedplus

autocmd FileType * setlocal formatoptions-=cro
cmap w!! w !sudo tee %

