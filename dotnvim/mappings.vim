" Better nav for omnicomplete
inoremap <expr> <C-j> ("\<C-n>")
inoremap <expr> <C-k> ("\<C-p>")

" tab in general mode will move to next buffer
nnoremap <TAB> :bnext<CR>
" shift-tab will go back to prev buffer
nnoremap <S-TAB> :bprevious<CR>
" alt-w will close buffer
nnoremap <M-w> :bw<CR>

nnoremap <BS> x
noremap! jj <Esc>

nnoremap <Leader>o o<Esc>
nnoremap <Leader>O O<Esc>

" Better window splitting
nnoremap <Leader>\ :vsplit<CR>
nnoremap <Leader>- :split<CR>

" Use alt + hjkl to resize windows
nnoremap <M-j>    :resize -2<CR>
nnoremap <M-k>    :resize +2<CR>
nnoremap <M-h>    :vertical resize -2<CR>
nnoremap <M-l>    :vertical resize +2<CR>

" Alternate way to save
nnoremap <C-s> :w<CR>
inoremap <C-s> <ESC>:w<CR>
" Alternate way to quit
nnoremap <C-q> :wq!<CR>
inoremap <C-q> <ESC>:wq!<CR>
nnoremap <M-q> :q!<CR>
inoremap <M-q> <ESC>:q!<CR>

" Clear search highlight by pressing ESC or ctrl+c
nnoremap <ESC> :noh<CR><ESC>
nnoremap <C-c> :noh<CR><ESC>

